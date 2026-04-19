# 后端服务架构 README

## 目标

这份文档用于说明后端主线模块如何装配、各模块负责什么、它们之间如何传递数据，以及后续模块化开发时应该把改动放在哪里。

目标不是重复所有实现细节，而是给出稳定的模块边界。

## 后端主线概览

当前后端是一个运行在 `Qt 6.2.4 + C++17` 上的原生服务，核心由以下几层组成：

1. 启动装配层
2. 设备/协议接入层
3. 点云处理与业务计算层
4. 数据持久化与库存业务层
5. 对外服务层

对应的核心入口类是：

- `Application`
- `HttpServer`
- `WebSocketServer`
- `PointCloudProcessor`
- `DatabaseManager`
- `PileManager`
- `MaterialHistoryManager`

## 启动装配层

入口文件：

- `backend/src/core/Application.cpp`
- `backend/include/core/Application.h`

`Application` 负责：

- 加载 `config/config.ini`
- 初始化数据库
- 初始化认证默认用户
- 初始化料堆管理
- 初始化雷达、PLC、视频管理器
- 初始化点云处理线程
- 初始化 WebSocket/HTTP 服务
- 把运行时配置下发到处理链

当前启动顺序是：

1. `ConfigManager`
2. `DatabaseManager`
3. `PileManager`
4. `LidarDriver`
5. `ModbusClient`
6. `VideoManager`
7. `PointCloudProcessor`
8. `MaterialHistoryManager`
9. `WebSocketServer`
10. `HttpServer`

这里的设计原则是：

- 先准备配置和基础依赖
- 再准备设备与处理链
- 最后开放网络接口

## 设备与协议接入层

### 雷达

核心类：

- `backend/include/drivers/lidar/LidarDriver.h`

职责：

- 屏蔽 Tanway SDK 平台差异
- 提供统一点云输入
- 暴露设备内标定信息

边界：

- 不承担业务判断
- 不负责体积、最高点、库存等业务语义

### PLC

核心类：

- `backend/include/protocols/modbus/ModbusClient.h`

职责：

- 读取 PLC 位姿和状态
- 执行远控写入
- 写最高点、控制命令、确认状态

边界：

- PLC 寄存器和协议适配留在这里
- HTTP 层不直接碰寄存器细节

### 视频

核心类：

- `backend/include/drivers/video/VideoManager.h`

职责：

- 管理 RTSP / ONVIF 参数
- 提供 PTZ、预置位、快照等能力
- 提供录像相关后端能力的承接点

边界：

- 不承担前端页面状态逻辑
- 不负责浏览器本地录像逻辑

## 点云处理与业务计算层

### PointCloudProcessor

核心类：

- `backend/include/processing/pcl/PointCloudProcessor.h`

职责：

- 作为点云处理主线程
- 接收雷达点云和 PLC 位姿
- 执行边界过滤、环形可视域过滤、最高点检测、地图更新、体积计算
- 输出诊断、最高点、全局地图和体积结果

它是后端算法主链的调度中心，不适合继续堆放 HTTP 或数据库逻辑。

补充说明：

- 轨迹窗口的切块原因和窗口状态都只通过诊断输出，不在这里额外复制一套状态机
- 最高点、轨迹窗口和盲区补偿属于同一条点云主链，现场排障时优先看 `PointCloudProcessor` 的诊断字段，而不是分散追各层日志
- `PointCloudProcessor::run()` 不能在持有 `m_mutex` 时再调用 `snapshotFrameAnalysisInput()` 或启动分析任务；这条路径在实机上曾把 worker 线程和 `enqueueFrameForAnalysis()` 一起卡死，表现为后端进程存活但 `/health`、`/api/auth/login`、WebSocket 都像失联。当前实现已改成先收集待启动任务再释放锁，后续 refactor 必须保留这个边界
- HTTP 服务在这个项目里可以保持 keep-alive；不要为了“看起来更干净”把每个响应都强制断开。真正常见的链路卡死来自点云 worker 线程和 Qt 主事件循环的锁问题，不是连接复用本身

### GlobalMapManager

核心类：

- `backend/include/processing/pcl/GlobalMapManager.h`

职责：

- 维护融合后的表面层地图
- 按表面栅格融合慢速移动过程中的多帧信息
- 提供地图快照和分区点云

这里承担“历史覆盖累积”的职责，当前中心盲区体积补偿优先依赖它，而不是直接依赖单帧环带点。

### VolumeCalculator

核心类：

- `backend/include/processing/pcl/VolumeCalculator.h`

职责：

- 按边界区域做体积积分
- 计算置信度、占据格数、补偿格数
- 对中心盲区做保守补偿

当前语义：

- 体积优先来自融合表面图
- 盲区补偿只用于修正系统性低估
- 不承担实时控制用途

现场调参时，如果 `volumeBlindZoneCoverageRatio` 长期偏低，通常应先检查轨迹覆盖和环形可视域；如果 `volumeBlindZoneDensityRatio` 偏低，再考虑调整环厚或分位数，而不是只盯最终 `volumeBlindZoneSupportRatio`。当前 `confidence` 也会同时考虑覆盖和密度，覆盖不足会比单纯密度不足更快拉低置信度。
盲区补偿的环厚、分位数和扇区数属于后处理参数，不应被当成控制闭环参数去联动 PLC。

### HighestPointDetector

核心类：

- `backend/include/processing/pcl/HighestPointDetector.h`

职责：

- 在有效 ROI 和过滤链结果上找最高点

当前语义：

- 高度直接取高置信度可见点的 `z`
- 不对中心盲区做激进插值

## 数据持久化与库存业务层

### DatabaseManager

核心类：

- `backend/include/service/DatabaseManager.h`

职责：

- 管理数据库连接
- 提供体积记录、物料记录等基础持久化操作

边界：

- 这里应保持为“数据库访问层”
- 不适合继续堆业务编排

### PileManager

核心类：

- `backend/include/service/PileManager.h`

职责：

- 管理料堆和物料类型
- 管理 ROI、库存体积、当前重量
- 对料堆信息提供统一查询入口

边界：

- 料堆元数据和 ROI 归它管
- 点云算法细节不应该放进来

### MaterialHistoryManager

核心类：

- `backend/include/service/MaterialHistoryManager.h`

职责：

- 管理物料增减记录
- 生成库存快照
- 执行盘存测量
- 统计历史变化

它是库存业务层的核心编排器，会消费：

- `PointCloudProcessor`
- `PileManager`
- `DatabaseManager`
- `ScaleManager`

## 对外服务层

### HttpServer

核心类：

- `backend/include/service/HttpServer.h`

职责：

- 注册并暴露 `/api/*` 路由
- 统一处理认证、配置、料堆、库存、控制、视频等接口
- 承接称重设备状态、设备配置与实时读数上报，把独立称重驱动边界隔离在 `ScaleManager`
  - 对外接口包括 `/api/scales/status`、`/api/scales/devices` 和 `/api/scales/readings`
  - `ScaleManager` 现在会按 `ui/scale_devices` 中的串口/网口 Modbus 参数主动轮询真实设备，回填实时重量、硬件在线状态和采样时间，外部驱动只作为兜底上报入口
- 承接系统维护接口，把备份、清缓存和重启安排落到后端受控执行
- 将 HTTP 请求分发给下层业务对象

当前它承担的内容偏多，已经是后端最大的汇聚点。

后续继续模块化时，应优先把这些路由按领域拆分：

- 认证与用户
- 配置管理
- 料堆与物料
- 历史与库存
- 控制与远控会话
- 视频与 ONVIF

### WebSocketServer

核心类：

- `backend/include/service/WebSocketServer.h`

职责：

- 广播点云、最高点、位姿、地图、诊断信息
- 给前端实时监控提供轻量推送通道

边界：

- 只做实时推送
- 不做业务写操作

## 主线数据流

### 1. 实时感知链

```text
LidarDriver -> PointCloudProcessor -> WebSocketServer -> Frontend
                     |
                     +-> HighestPoint -> PLC / Frontend
                     +-> GlobalMapManager
                     +-> VolumeCalculator
```

### 2. 库存盘存链

```text
PointCloudProcessor / GlobalMapManager
            ->
MaterialHistoryManager
            ->
PileManager + DatabaseManager
            ->
ScaleManager
            ->
HttpServer /api/inventory* /api/history* /api/volume-records /api/scales*
```

### 3. 控制链

```text
Frontend -> HttpServer -> ModbusClient -> PLC
Frontend -> HttpServer -> VideoManager -> ONVIF Camera
```

## 模块边界建议

后续开发时，按下面原则收口：

- 新的点云过滤、体积、最高点逻辑，优先放 `processing/pcl`
- 新的相机/ONVIF/录像能力，优先放 `drivers/video`
- 新的 PLC 寄存器语义和控制确认，优先放 `protocols/modbus`
- 新的库存/历史业务编排，优先放 `service/MaterialHistoryManager`
- 新的料堆和 ROI 元数据，优先放 `service/PileManager`
- 新的 HTTP 接口接线，优先放 `service/HttpServer`，再视复杂度拆独立 handler

不要把这些内容混在一起：

- 不要在 `HttpServer` 里写具体算法
- 不要在 `DatabaseManager` 里写业务决策
- 不要在 `PointCloudProcessor` 里写 HTTP 或 SQL

## 当前可继续拆分的点

1. `HttpServer` 路由过于集中，建议继续按领域拆 handler
2. 视频链路缺少独立 README，后续单独整理
3. PLC 控制链路缺少独立 README，后续单独整理
4. 自动任务 `AutoTaskManager` 还没有接入主线说明，后续若恢复该模块，应单独建文档说明其状态和边界

## 代码入口

- `backend/src/core/Application.cpp`
- `backend/src/service/HttpServer.cpp`
- `backend/src/service/WebSocketServer.cpp`
- `backend/src/processing/pcl/PointCloudProcessor.cpp`
- `backend/src/processing/pcl/GlobalMapManager.cpp`
- `backend/src/processing/pcl/VolumeCalculator.cpp`
- `backend/src/service/PileManager.cpp`
- `backend/src/service/MaterialHistoryManager.cpp`
