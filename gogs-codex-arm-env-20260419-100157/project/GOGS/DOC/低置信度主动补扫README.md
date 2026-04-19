# 低置信度主动补扫 README

## 目标

当中心盲区或局部区域点云置信度不足时，系统理论上可以主动控制行车移动到更合适的位置重新扫描。

这项能力不是单纯的点云算法优化，而是三条链路的联合设计：

- 算法诊断
- 控制调度
- 作业优先级与安全互斥

当前文档先把设计边界和主线方案定清楚，后续再按现场验证逐步实现。

## 现场前提

- 雷达垂直朝下
- 静态可视域是带中心盲区的环形有效扫描区
- 行车在盘存或扫描过程中会缓慢移动，因此单帧盲区中心通常能被前后帧的环带覆盖
- 目标平台是固定配置的 ARM Linux 主机，优先做现场主线，不为泛兼容扩散设计

## 这项能力解决什么问题

典型触发场景：

- 最高点持续无效
- 环带保留率过低
- 盲区补偿支撑率过低
- 某块 ROI 长时间空洞，但从业务上判断该区域应当可观测
- 体积估算对盲区补偿依赖过高，结果可信度下降

核心目标不是“自动乱跑补数据”，而是：

- 尽量让补扫动作只发生在低风险空闲窗口
- 让系统区分“建议补扫”和“允许自动补扫”
- 让补扫结果能回写到诊断和历史里，便于复盘

## 优先级原则

补扫必须服从下面的优先级顺序：

1. 人工作业与人工远控
2. 安全停机、故障、急停
3. 正式自动作业
4. 主动补扫

任何补扫动作都不能打断更高优先级任务。

## 必须满足的互斥条件

进入主动补扫前，至少要满足：

- 当前没有抓取、放料、走正式工艺路径
- 当前没有远控会话占用
- PLC 不处于故障、急停、限位异常状态
- 当前控制模式允许系统发起受控移动
- 相机、雷达、PLC 状态都处于可继续观测的正常区间

只要上述任意一条不成立，就只能给出“建议补扫”，不能自动执行。

## 推荐实现分层

推荐新增独立的 `RescanCoordinator`，不要把控制编排直接塞进 `PointCloudProcessor`。

分层建议如下：

- `PointCloudProcessor`
  - 只负责产出低置信度诊断
  - 不直接下发控制命令
- `RescanCoordinator`
  - 负责判断是否需要补扫
  - 负责检查互斥条件和优先级
  - 负责把“建议目标位姿”转成可执行计划
- `HttpServer`
  - 提供诊断查询
  - 提供建议补扫和受控执行接口
- 控制链路
  - 继续复用现有 `/api/control/request`、`/api/control/goto`、`/api/control/release`

## 触发判据

建议先用一组简单且可解释的指标：

- `highestPointValid == false` 连续出现超过阈值
- `ringVisibleKeepRatio` 低于阈值
- `volumeBlindZoneSupportRatio` 低于阈值
- `blindZoneRejectedPoints` 长时间偏高且 ROI 内存在待观测目标
- 某些关键网格连续多帧没有形成有效表面

其中 `volumeBlindZoneSupportRatio` 已按环带厚度归一化，更适合判断慢速扫描下的真实覆盖不足，而不是只看扇区里有没有零星样本。
如果要进一步判断该调轨迹还是调参数，可以继续拆看：

- `volumeBlindZoneCoverageRatio`：盲区外圈覆盖了多少扇区
- `volumeBlindZoneDensityRatio`：已覆盖扇区里的样本密度是否足够

为了避免误触发，触发判据应同时满足：

- 连续多帧出现
- 当前处于非生产关键阶段
- 上一次补扫结束后已超过冷却时间

## 补扫执行模式

建议分两档：

### 1. 建议补扫

系统只输出：

- 是否建议补扫
- 建议目标位姿
- 建议原因
- 当前被哪个高优先级动作阻塞

前端只做提示，不自动下发控制。

### 2. 自动补扫

只有在显式开启“允许自动补扫”后才执行：

- 请求控制会话
- 下发 `goto`
- 到位后等待若干帧稳定扫描
- 评估是否恢复置信度
- 完成后释放控制会话

## 建议目标位姿策略

第一版不要做复杂路径规划，只做保守策略：

- 沿当前 ROI 的低置信度方向，向外平移一个可视环带宽度
- 避开当前盲区中心，让低置信度区域落到下一位置的有效环带上
- 不主动改动危险姿态或边界附近姿态

这样能先验证补扫主线是否有效，再决定后续是否做更复杂的目标优化。

## 停止条件

补扫执行中任意满足下面条件都应停止：

- 到达目标位姿
- 低置信度指标恢复到目标区间
- 超时
- 人工接管
- PLC 故障、急停、限位或模式变化

## 结果回写

补扫完成后至少要回写这些结果：

- 补扫前后的 `highestPointValid`
- 补扫前后的 `ringVisibleKeepRatio`
- 补扫前后的 `volumeBlindZoneCoverageRatio`
- 补扫前后的 `volumeBlindZoneDensityRatio`
- 补扫前后的 `volumeBlindZoneSupportRatio`
- 补扫耗时
- 实际执行位姿
- 是否被人工打断
- 是否真正改善了体积或最高点稳定性

## 建议接口

第一版建议新增只读与受控接口，不要一步做到全自动。

建议接口：

- `GET /api/rescan/status`
- `POST /api/rescan/analyze`
- `POST /api/rescan/execute`
- `POST /api/rescan/cancel`

其中：

- `analyze` 只返回建议，不执行控制
- `execute` 必须显式带上“允许自动补扫”的前提

当前状态：

- `GET /api/rescan/status` 已实现
- `POST /api/rescan/analyze` 已实现
- `POST /api/rescan/execute` 在 `allowAutoExecute=false` 时返回 preview，在 `allowAutoExecute=true` 且持有控制会话时进入真实 `goto`
- `POST /api/rescan/cancel` 在 `allowAutoExecute=false` 时返回 preview，在 `allowAutoExecute=true` 且持有控制会话时进入真实 `stop`
- `RescanCoordinator` 最小骨架已落地，当前先承接只读分析缓存和统一数据结构
- 补扫分析字段的后端拼装逻辑已收口到 `RescanCoordinator`
- `RescanExecutionRequest / RescanExecutionResult / RescanCancelResult` 数据结构已补齐，用于后续 execute/cancel 落地
- `status/analyze` 只返回只读诊断、建议补扫原因和控制是否允许的判定结果
- `execute/cancel` 真实执行会在持有控制会话时直接下发 `goto/stop`，并回传最新分析快照
- 当前已返回统一阻塞原因 `blockedReason`
- 当前已返回保守版建议目标位姿 `suggestedTarget`
- 当前已返回建议优先级 `suggestionPriority` 与建议置信度 `suggestionConfidence`
- 当前已返回非执行态状态机字段：`coordinatorState / executionState / analysisRevision / updatedAt`
- 当前已返回显式能力阶段字段：`controlPhase`
  - `status/analyze` 固定为 `analysis_only`
  - `execute/cancel` preview 返回固定为 `preview_only`
  - `execute/cancel` 真实执行返回固定为 `live_control`
- `execute/cancel` 返回均会附带当前 `analysis` 快照，前端可直接复用状态
- 前端已补 `frontend/src/utils/rescan.js`，统一消费补扫分析字段，避免多页各自解释
- `execute/cancel` 已支持真实控制，但仍保留 preview 语义作为只读入口
- `execute/cancel` 真实执行已接入完成态回写与超时监测，`commandCompleted / commandFailed / writeConfirmFailed / heartbeatTimeout / disconnected` 会驱动执行状态回写
- 监控页已显式区分“预览模式”和“执行模式”，避免联调时混淆
- 监控页已补“刷新分析 / 执行补扫 / 停止补扫”入口，便于现场直接验证真实控制返回结构和阻塞原因
- 返回已补请求回显：`requestedBy / requestReason / targetPose`
- 若当前 PLC 位姿无效，补扫分析不会再返回建议目标位姿，避免前端把无效目标误展示成可执行建议
- 监控页和结果区已显示 `analysisRevision / updatedAt`，便于现场判断当前查看的是不是最新一轮分析
- 监控页已把预览结果和执行结果分别标注为“预览模式 / 执行模式”，避免联调时和真实执行混淆
- 监控页已补 `执行状态 / 执行动作 / 执行开始 / 执行结束`，便于现场判断 goto/stop 是否真正完成回写
- 当前执行状态允许出现 `executing / cancelling / completed / cancelled / failed / timed_out`
- 还没有进入自动补扫的自动接管阶段，真实执行仍要求显式控制会话与人工触发

## 当前不做的事

这一阶段先不做：

- 通用路径规划器
- 多目标补扫排序器
- 与所有可能摄像头/PLC 兼容的泛化策略
- 面向多机型的动态插件化控制层

原因很简单：当前项目目标是固定环境稳定运行，先把现场主线做通。

## 下一步代码落点

推荐按这个顺序推进：

1. 先把低置信度判据整理成统一诊断输出
2. 再做 `RescanCoordinator` 只读分析
3. 再加前端“建议补扫”展示
4. 最后再做受控自动执行

## 相关代码位置

- `backend/src/processing/pcl/PointCloudProcessor.cpp`
- `backend/src/service/HttpServer.cpp`
- `backend/src/protocols/modbus/ModbusClient.cpp`
- `frontend/src/views/MonitorView.vue`
- `frontend/src/views/RemoteOperationView.vue`
- `todo.md`
