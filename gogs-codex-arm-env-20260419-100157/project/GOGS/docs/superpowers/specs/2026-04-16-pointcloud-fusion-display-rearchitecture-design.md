# 点云融合与显示重构设计

## 1. 目标

在当前“单帧原始点云已稳定显示、后台处理链已临时关闭”的基础上，重构点云显示与融合架构，满足以下目标：

- 单帧原始点云显示与融合/测量链彻底硬隔离
- 盘存/体积测量精度优先
- 监控页和回放页只要求直观查看点云轮廓
- 整体性能优先，避免再出现后台处理链拖死后端、导致前端断连
- 融合链按轨迹段/停稳后提交结果，不再追求逐帧实时融合
- 融合链遵守“一次几何降采样/量化”的原则

## 2. 当前问题

结合现有代码、测试机部署记录和运行日志，当前链路存在三类核心问题：

### 2.1 单帧显示和融合链语义混杂

- 单帧原始显示链已经改成 `SDK -> WebSocketServer -> MonitorView`
- 但历史上的 `PointCloudProcessor` 仍然承担了过多角色：
  - 后台处理
  - 轨迹融合
  - 地图更新
  - 诊断输出
  - 体积相关输入准备
- 这使得“看点云”和“算点云”虽然逻辑上已经分开，结构上却仍互相影响

### 2.2 当前融合链逐帧开销过大

- 现有 `PointCloudProcessor` 以逐帧分析、逐帧提交为中心
- 每帧都会经历大量点级处理和对象复制
- 测试机现场已确认：
  - 仅关闭 `enable_map_building` 不能阻止内存飙升
  - 必须关闭整个 `enable_point_cloud_processing` 才能稳定
- 这说明真正的瓶颈不只在全局地图快照，而在当前逐帧处理模式本身

### 2.3 当前测量链和显示链目标不一致

- 单帧原始显示的目标是“稳定、直观、不断流”
- 盘存/体积测量的目标是“世界坐标一致、噪声可控、段级结果可靠”
- 回放/监控融合结果只需要轮廓，不需要保留与测量同等级的点密度
- 现有实现没有把这三种目标明确拆开

## 3. 设计原则

本次重构固定采用以下原则：

### 3.1 双链硬隔离

- 原始单帧显示链独立存在，不依赖融合链状态
- 融合链的排队、提交、失败、降频都不能影响原始单帧显示

### 3.2 测量优先

- 盘存/体积结果是主目标
- 监控页和回放页的融合点云仅承担轮廓展示职责
- 不允许为了页面显示更轻而破坏测量输入质量

### 3.3 段式提交

- 融合结果只在轨迹段结束或停稳后提交
- 不再追求“每来一帧就更新一次融合地图”
- 这样把实时性预算优先让给原始单帧显示

### 3.4 一次几何量化

- 融合链只保留一次几何量化/降采样
- 该量化结果既是测量输入，也是显示轮廓来源
- 不再允许“每帧降一次、融合后再降一次、显示前再降一次”的多次几何缩减

### 3.5 结构优先于补丁

- 不再继续在现有 `PointCloudProcessor` 上追加条件分支修补
- 需要明确新旧职责边界，并逐步把旧处理器降级为协调层或退役

## 4. 目标架构

### 4.1 原始单帧显示链

目标链路：

`Tanway SDK -> LidarDriver -> RawFrameDisplayService -> WebSocketServer -> MonitorView`

职责限定：

- 输入：SDK 原始单帧点云
- 坐标系：雷达本地坐标系
- 允许处理：
  - 非有限点过滤
  - 可选方向裁切
  - 一次显示体素降采样
  - WebSocket 分块与背压控制
- 禁止处理：
  - PLC 位姿变换
  - 轨迹融合
  - ROI
  - SOR
  - adaptive/temporal 边界
  - 体积估算
  - 全局地图累计

这一条链的目标是“前端始终有可看的实时单帧”，它不参与测量。

### 4.2 段式融合链

目标链路：

`Tanway SDK raw frame -> FusionSegmentCollector -> SegmentAccumulator -> SegmentCommit -> FusionResultStore -> MeasurementService / FusionPreviewPublisher`

核心思想：

- 原始帧进来后，不再逐帧跑完整后处理
- 先按轨迹段聚合，再在段结束时提交一次融合结果
- 聚合阶段直接构建段级 canonical surface cells，而不是缓存巨大的完整点云副本

### 4.3 推荐核心数据结构：段级表面单元

融合链的 canonical representation 固定为“段级表面单元格（surface cells）”，而不是“段级大点云”。

每个单元保存：

- 世界坐标平面位置
- 高程统计
- 最高点/均值
- 强度统计
- 命中次数
- 稳定命中次数
- 最近更新时间

这样做的结果：

- 每个原始点在进入融合链时只被量化一次
- 后续测量、轮廓显示、快照导出都共享同一份 canonical cells
- 避免大点云持续拼接、拷贝、再降采样导致的内存膨胀

## 5. 模块拆分

### 5.1 `RawFrameDisplayService`

职责：

- 从 `LidarDriver::pointCloudReceived` 接原始点云
- 做显示链允许的最小处理
- 输出原始单帧显示消息

输出：

- `pointCloud` WebSocket 流
- `rawCount / finiteCount / displayCount / voxelSize`

不负责：

- 世界坐标
- 融合
- 测量

### 5.2 `FusionSegmentCollector`

职责：

- 读取当前 PLC 位姿和运动状态
- 判定当前帧属于哪个轨迹段
- 管理段开始、段延续、段关闭

段关闭触发条件：

- 停稳
- 方向变化导致应结束当前段
- 超过距离上限
- 超过时间上限
- 后端停止或显式 flush

### 5.3 `SegmentAccumulator`

职责：

- 在段存活期间，把每帧点云转换到世界坐标
- 直接更新段级 surface cells
- 不保留无限增长的逐帧全量点云缓存

允许的点级处理应压到最低，只保留对测量有硬价值的步骤：

- 非有限点过滤
- 世界坐标变换
- 必要的可视域/方向约束
- 单次表面单元量化

不再把逐帧 `adaptive boundary + temporal boundary + ROI + SOR + 再降采样` 作为主路径。

### 5.4 `FusionProcessor`

职责：

- 在段关闭时对段级 cells 做 finalize
- 输出测量用结果和预览用结果

finalize 规则：

- 根据命中次数和稳定命中次数去除低置信单元
- 生成测量边界和轮廓边界
- 生成 canonical fused cloud（由 cells 转成点）

注意：

- 这里不再做第二次几何降采样
- 预览云直接来自同一份 canonical cells 转点

### 5.5 `FusionResultStore`

职责：

- 保存最近一次已提交段的融合结果
- 保存测量输入结果
- 保存快照导出源

保存对象：

- latest fusion preview
- latest measurement cloud
- latest segment metadata
- snapshot export source

存储策略：

- 只保留最近结果和必要历史快照
- 不保留无限增长的内存态全局大点云

### 5.6 `MeasurementService`

职责：

- 只基于已提交段的 canonical cells / fused cloud 计算盘存和体积
- 不消费原始单帧
- 不直接参与监控页实时流

### 5.7 `FusionPreviewPublisher`

职责：

- 把最新提交段的融合轮廓结果推给监控页和回放页
- 只发送用于轮廓查看的融合结果
- 不回退成“假实时”

## 6. 数据语义

### 6.1 原始单帧流

- 来源：SDK 原始帧
- 坐标系：雷达本地坐标系
- 用途：监控页实时观察
- 更新频率：高频

### 6.2 融合预览流

- 来源：段提交后的 canonical fused cells
- 坐标系：世界坐标系
- 用途：监控页自动切换后的轮廓显示、回放页轮廓显示
- 更新频率：低频，仅段提交时

### 6.3 测量云

- 来源：与融合预览同源的 canonical fused cells
- 坐标系：世界坐标系
- 用途：盘存/体积
- 要求：主精度输入

### 6.4 快照/回放导出

- 默认导出来源：已提交段的 canonical fused cells 转点云
- 语义：可视轮廓优先，不承诺保留原始逐点密度

## 7. 监控页行为

监控页默认规则固定为：

- 新段正在采集中：默认显示原始单帧
- 段提交成功：自动切换到最新融合结果
- 用户手动切回原始单帧：允许
- 新段开始后：自动恢复显示原始单帧，直到下一次段提交

禁止行为：

- 原始单帧为空时自动回退到旧融合结果冒充当前实时数据
- 融合链卡住时影响原始单帧展示

建议新增前端视图状态：

- `raw`
- `fusion`
- `auto`

默认值为 `auto`。

## 8. 一次降采样/量化规则

本次重构明确区分两类“缩减”：

### 8.1 原始单帧显示链

原始单帧仍允许保留一次显示体素降采样，因为它只服务监控页实时渲染，不参与测量。

### 8.2 融合链

融合链只能保留一次几何量化：

- 原始点变到世界坐标后，进入段级 surface cells
- canonical cells 就是融合链唯一的几何量化结果
- 后续测量、预览、快照导出都基于这份结果

因此融合链内不再允许：

- 每帧体素降采样一次
- 段提交后再对融合结果做第二次体素降采样
- 为监控页预览再做第三次几何缩减

## 9. 精度策略

### 9.1 用段级稳定性替代逐帧重滤波

盘存/体积精度优先依赖：

- 正确的世界坐标变换
- 正确的段边界
- 足够的段内覆盖
- 单元命中次数/稳定次数

而不是继续依赖一条昂贵的逐帧 `adaptive + temporal + SOR + ROI` 组合链。

### 9.2 必要过滤只保留硬价值项

保留条件：

- 对测量精度有直接收益
- 能在段级 canonical cells 上表达
- 不引入大规模点云拷贝

优先保留：

- 非有限点过滤
- 世界坐标变换
- 置信命中阈值
- 必要的盲区/可视域约束

谨慎保留或改为段级规则：

- ROI
- temporal boundary
- adaptive boundary
- SOR

## 10. 性能策略

### 10.1 原始显示链与融合链分预算

- 原始单帧链：只承担实时显示预算
- 融合链：只承担段提交预算

任何融合链阻塞都不能反压到原始单帧显示。

### 10.2 限制内存增长源

不得再出现以下内存模式：

- 每帧保留完整点云副本
- 轨迹段累计大点云后再全量复制
- 全局地图每次更新都生成完整快照副本

新设计应优先：

- 逐帧更新段级 cells
- 段结束只提交结构化结果
- 结果存储保留最近结果，不保留无限历史

### 10.3 WebSocket 保留现有背压协议

保留并继续强化：

- chunk
- ack
- backlog soft/hard limit
- 只给 ready client 发下一帧

## 11. 配置设计

建议把配置拆成三组，而不是继续混用 `processing/*`：

### 11.1 原始单帧显示配置

- `display/raw_frame_voxel_size`
- `display/raw_frame_directional_clip_enabled`
- `display/raw_frame_directional_clip_axis`
- `display/raw_frame_directional_clip_half_angle_deg`
- `display/raw_frame_directional_clip_angle_offset_deg`
- `display/raw_frame_directional_clip_invert`

### 11.2 融合链配置

- `fusion/enabled`
- `fusion/commit_mode=segment`
- `fusion/measurement_cell_size`
- `fusion/max_open_segment_frames`
- `fusion/max_open_segment_points`
- `fusion/force_commit_distance_m`
- `fusion/force_commit_seconds`
- `fusion/stationary_min_frames`
- `fusion/min_stable_hits`
- `fusion/min_confident_hits`

### 11.3 监控页自动切换配置

- `display/monitor_auto_switch_to_fusion`
- `display/monitor_default_mode=auto`

兼容策略：

- 现有 `processing/enable_point_cloud_processing` 在迁移阶段继续保留
- 最终语义收口为 `fusion/enabled`

## 12. 迁移顺序

### 阶段 1：固定单帧链

- 保持当前原始单帧链稳定
- 不动前端点云显示协议
- 明确原始流为单独服务职责

### 阶段 2：引入段级 accumulator

- 新建段级 surface cell accumulator
- 接管 `PointCloudProcessor` 中最重的逐帧点云缓存职责
- 先不接体积，只做段提交和预览结果

### 阶段 3：测量迁移

- `MeasurementService` 改为吃段提交后的 canonical fused result
- 旧逐帧测量输入链保留为临时回退，不再默认启用

### 阶段 4：监控页自动切换

- 加入 `auto/raw/fusion` 三态模式
- 段提交成功后自动切到融合预览

### 阶段 5：回放/快照切换

- 回放和快照导出默认转向 canonical fused result
- 明确其产品语义为“轮廓查看”

### 阶段 6：旧处理器瘦身

- 逐步把 `PointCloudProcessor` 降级为融合协调入口
- 去掉逐帧重分析主路径

## 13. 回归验证

本设计落地后必须以以下口径验收：

### 13.1 稳定性

- 原始单帧流开启时，前端长时间保持连接
- 后端 RSS 不再随融合链开启而线性飙升
- 融合链开启后，原始单帧仍持续更新

### 13.2 性能

- 原始单帧帧率不被段式融合显著拉低
- 段内内存增长受控
- 段提交耗时可预测，不出现长时间卡死

### 13.3 精度

- 盘存/体积结果与当前正确单帧方向、世界坐标基线一致
- 段提交结果在停稳和轨迹段边界上可复现

### 13.4 显示语义

- 监控页在段采集中显示原始单帧
- 段提交后自动切到融合结果
- 回放和快照展示的是融合轮廓，不再伪装成原始逐帧数据

## 14. 非目标

本次重构不追求以下目标：

- 融合地图逐帧实时更新
- 回放/快照保留原始逐点密度
- 在同一条链里同时满足“实时原始显示”和“高精度测量融合”
- 对所有历史配置键保持完全不变的产品语义

## 15. 结论

本次推荐方案是：

- 保留独立原始单帧显示链
- 用“段级 surface cells”替代“逐帧大点云后处理”
- 融合链只做一次世界坐标后的几何量化
- 以段提交结果作为测量主输入
- 让监控页在段提交后自动切到融合轮廓结果

这是当前在“性能优先、测量优先、显示不拖死系统”的约束下，风险最低、收益最高的重构方向。
