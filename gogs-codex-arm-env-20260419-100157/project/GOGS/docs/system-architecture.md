# 系统架构文档

> 最后更新：2026-04-16
> 定位：前后端协同全貌、主控链路、页面-API 映射、关键数据流

---

## 1. 系统概述

**抓斗作业引导及盘存系统**：面向行车抓斗作业场景，完成激光雷达点云采集、PLC 位姿接入、点云融合建图、最高点检测、体积盘存、历史回放和前端可视化。

### 1.1 当前推荐阅读与执行入口

- 总览先看：[README.md](../README.md)
- 快速建立上下文先看：[GOGS RTK（快速上手包）](gogs-rtk.md)
- 现场部署与测试机发布先看：[DOC/部署与运维README.md](../DOC/部署与运维README.md) 和 [scripts/arm/README.md](../scripts/arm/README.md)

当前维护口径：

- 在 Codex / CLI 会话里，命令统一建议使用 `rtk` 前缀
- 前端整体验证优先使用 `rtk npm --prefix frontend run build` 和 `rtk npm --prefix frontend test`
- ARM 测试机发布优先使用 `rtk bash scripts/arm/pipeline.sh` 或其 `--frontend-only` / `deploy_frontend.sh` 变体

### 物理拓扑

```
┌─────────────────┐      ┌────────────────────────────┐      ┌─────────────────┐
│  车载感知单元   │      │  ARM Debian 11 边缘服务器   │      │  远程监控终端   │
│  ┌───────────┐  │      │  ┌──────────────────────┐  │      │  ┌───────────┐  │
│  │48线雷达   │──┼──────┼─▶│ Qt C++ 后端服务       │  │      │  │PC/平板/   │  │
│  └───────────┘  │      │  │ - 雷达/PLC/点云处理   │  │      │  │手机浏览器 │  │
│  ┌───────────┐  │      │  │ - HTTP API :8080      │◀─┼──────┼──┤           │  │
│  │400万球机  │──┼──────┼─▶│ - WebSocket :12345    │  │      │  └───────────┘  │
│  └───────────┘  │      │  ├──────────────────────┤  │      │                 │
│                 │      │  │ MySQL 8.0 + mediamtx  │  │      │                 │
└─────────────────┘      └────────────┬─────────────┘  └─────────────────┘
                                      │ Modbus TCP/RTU
                                 ┌────▼────┐
                                 │ 行车 PLC │
                                 │ (X, Y)   │
                                 └──────────┘
```

## 2. 技术栈

| 层 | 技术 | 版本 |
|----|------|------|
| 后端语言 | C++17 | — |
| 后端框架 | Qt 6.2.4 | 6.2.4 |
| 点云处理 | PCL 1.11.1 + Eigen 3.3.9 | 1.11.1 / 3.3.9 |
| 工业通信 | Qt SerialBus (Modbus TCP/RTU) | — |
| 数据库 | MySQL 8.0 (QtSql QMYSQL) | 8.0 |
| 视频流 | GStreamer + mediamtx | 1.18+ |
| 雷达 SDK | Tanway LidarView | — |
| 前端框架 | Vue 3 + Vite | 3.3.4 / 5.4.14 |
| 前端 UI | Element Plus | 2.3.14 |
| 3D 可视化 | Three.js | 0.155.0 |
| 图表 | ECharts 5 | 5.4.3 |
| 前端状态 | Pinia | 2.1.6 |
| 目标平台 | ARM64 Debian 11 (RK3588) | — |

## 3. 后端核心架构

### 3.1 Application 装配顺序

```
main.cpp
  └─ Application
       ├─ ConfigManager       ← config/config.ini（首次启动自动生成补全）
       ├─ DatabaseManager     ← 自动建库/建表/补列/补索引
       ├─ LidarDriver         ← Tanway SDK（ARM/Win 双平台）
       ├─ ModbusClient        ← Qt SerialBus（PLC V2.0 寄存器）
       ├─ VideoManager        ← GStreamer 录像 + ONVIF PTZ
       ├─ ScaleManager        ← Modbus 轮询称重设备
       ├─ PointCloudProcessor ← PCL 处理管线（体素/滤波/ROI/表面融合/体积）
       ├─ GlobalMapManager    ← 2D 表面层网格地图
       ├─ HighestPointDetector← 实时最高点检测
       ├─ VolumeCalculator    ← ROI 体积积分 + 盲区补偿
       ├─ PileManager         ← 料堆 ROI/体积/密度管理
       ├─ MaterialHistoryManager ← 物料操作历史
       ├─ AutoTaskManager     ← 自动盘存任务调度
       ├─ RescanCoordinator   ← 低置信度补扫分析/执行
       ├─ AuthManager         ← JWT 认证 + 角色权限
       ├─ HttpServer          ← REST API (:8080)
       └─ WebSocketServer     ← 实时推送 (:12345)
```

### 3.2 后端源码目录

```
backend/
├── src/
│   ├── main.cpp              # 入口
│   ├── core/
│   │   ├── Application.cpp   # 主控装配
│   │   └── ConfigManager.cpp # 配置管理
│   ├── drivers/
│   │   ├── lidar/            # 雷达驱动（Tanway SDK wrapper）
│   │   └── video/            # 视频管理（GStreamer + ONVIF）
│   ├── processing/pcl/       # 点云处理（7 个模块）
│   │   ├── PointCloudProcessor.cpp       # 主处理线程（帧队列/丢帧/轨迹窗口）
│   │   ├── GlobalMapManager.cpp          # 2D 表面层网格
│   │   ├── HighestPointDetector.cpp      # 最高点检测
│   │   ├── VolumeCalculator.cpp          # 体积积分 + 盲区补偿
│   │   ├── CoordinateTransformer.cpp     # 坐标变换
│   │   └── PointCloudProcessingUtils.cpp # 工具函数
│   ├── protocols/modbus/     # ModbusClient（PLC 读写）
│   ├── service/
│   │   ├── HttpServer.cpp    # 80+ 条 REST 路由
│   │   ├── WebSocketServer.cpp # 实时推送
│   │   ├── DatabaseManager.cpp # MySQL 操作
│   │   ├── PileManager.cpp   # 料堆管理
│   │   ├── MaterialHistoryManager.cpp # 物料历史
│   │   ├── AutoTaskManager.cpp # 自动盘存
│   │   ├── RescanCoordinator.cpp # 补扫协调
│   │   └── ScaleManager.cpp  # 称重设备
│   ├── auth/                 # 认证与用户管理
│   └── utils/                # Logger / RingBuffer / Types
└── include/                  # 对应头文件
```

## 4. 核心业务链路

### 4.1 实时监控链路（主链路）

```
雷达 48 线点云 ──→ LidarDriver ──→ PointCloudProcessor
                                        │
    PLC Modbus ──→ ModbusClient ───────┤ (位姿 X/Y/Z/theta + 状态字)
                                        │
                                        ├─ 外参变换 → 环形可视域过滤 → 统计滤波
                                        ├─ 轨迹窗口融合 → GlobalMapManager 表面更新
                                        ├─ HighestPointDetector → 最高点
                                        ├─ VolumeCalculator → 体积（含盲区补偿）
                                        └─ processingDiagnostics (30+ 诊断字段)
                                              │
                                              ├─→ WebSocketServer 推送前端
                                              ├─→ HttpServer API 查询
                                              └─→ ModbusClient 写 PLC（最高点/心跳）
```

### 4.2 体积盘存链路

```
前端 POST /api/inventory/measure
  └─ HttpServer ──→ PointCloudProcessor.getCurrentMapData()
                    └─ GlobalMapManager.getRegionGrid()
                         └─ VolumeCalculator.calculateVolume(roi, grid)
                              ├─ ROI 内网格体积积分
                              ├─ 中心盲区保守补偿
                              ├─ 置信度评估（覆盖/密度/支撑率）
                              └─→ DatabaseManager 保存快照
                                   └─→ PCD 文件导出
```

### 4.3 远程控制链路

```
前端 POST /api/control/request  → HttpServer → AuthManager 验证
前端 POST /api/control/move     → HttpServer → ModbusClient.writeHoldingRegisters()
前端 POST /api/control/stop     → HttpServer → ModbusClient.writeHoldingRegisters()
前端 POST /api/control/emergency → HttpServer → ModbusClient（急停命令）

PLC 命令确认链：
  写 HR_CMD_xxx → 读 HR_WRITE_CONFIRM → 读 HR_CMD_STATUS → 读 HR_CMD_RESULT
```

### 4.4 配置管理链路

```
前端 GET /api/config/schema  → HttpServer → ConfigManager.getSchema()
前端 POST /api/config        → HttpServer → ConfigManager.setValue()
                                   │
                                   ├─ applyMode=live: 即时生效
                                   └─ restartRequired: 需重启后端
                                        └─ config.ini 持久化
```

## 5. 前端页面 ↔ 后端 API 映射

| 前端页面 | 路由 | 主要 API | WebSocket |
|---------|------|---------|-----------|
| LoginView | /login | POST /api/auth/login | — |
| DashboardView | /dashboard | GET /api/status, /api/system/info, /api/piles, /api/statistics, /api/operations/points | ✓ (status/highestPoint) |
| MonitorView | /monitor | GET /api/piles, /api/video/*, /api/control/*, /api/rescan/* | ✓ (全部类型) |
| InventoryView | /inventory | GET /api/inventory-snapshots*, /api/piles, /api/material-types, POST /api/inventory/measure | — |
| HistoryView | /history | GET /api/history/*, /api/piles, /api/material-types | — |
| PlaybackView | /playback | GET /api/inventory-snapshots*, /api/video-records, /api/history/*, /api/monitor/trajectory | — |
| RemoteOperationView | /remote | /api/control/*, /api/piles, /api/control/statistics | — |
| ConfigCenterView + views/config/* | /config/* | GET/POST /api/config*, /api/config-center/*, /api/piles, /api/material-types, /api/scales/*, /api/system/maintenance/* | — |
| FeatureSwitchView | /features | GET/PUT /api/features | — |

## 6. WebSocket 消息协议

服务端 → 客户端：

| type 字段 | 数据内容 | 消费组件 |
|-----------|---------|---------|
| `status` | `{ status: "running" }` | DashboardView |
| `pointCloudMeta` | `{ source, sequence, timestamp, rawCount, displayCount, voxelSize, chunkCount }` | `system store` 组装单帧点云 |
| `pointCloudChunk` | `{ source, sequence, chunkIndex, chunkCount, points:[...] }` | `system store` 追加单帧点云块 |
| `fusionPreviewMeta` | `{ source, sequence, timestamp, rawCount, displayCount, voxelSize, chunkCount }` | `system store` 组装融合预览 |
| `fusionPreviewChunk` | `{ source, sequence, chunkIndex, chunkCount, points:[...] }` | `system store` 追加融合预览块 |
| `pointCloud` | `{ source, sequence, timestamp, rawCount, displayCount, voxelSize, points:[...] }` | `system store` 兼容完整单帧 payload |
| `fusionPreview` | `{ source, sequence, timestamp, rawCount, displayCount, voxelSize, points:[...] }` | `system store` 兼容完整融合预览 payload |
| `globalMap` | `{ source:"globalMap", sequence, timestamp, rawCount, displayCount, voxelSize, points:[...] }` | MonitorView / `system store` |
| `gantryPose` | `{ x, y, z, theta, grabAngle, loadWeight, status, ... }` | MonitorView, RemoteOperationView |
| `highestPoint` | `{ valid, relative: {x,y,z}, absolute: {x,y,z} }` | DashboardView, MonitorView |
| `volumeRecords` | `[...]` | InventoryView |
| `processingDiagnostics` | 30+ 字段（帧率/保留率/盲区/轨迹窗口/补扫建议） | MonitorView DiagnosticsPanel |

补充说明：

- 当前主线里，单帧点云 `pointCloud` 和融合预览 `fusionPreview` 默认按 `Meta + Chunk` 分片发送；前端 store 仍兼容完整 payload，作为降级或回归通道保留。
- `globalMap` 仍以完整消息发送，但已经补齐和单帧点云一致的 `sequence / rawCount / displayCount / voxelSize / source` 元数据。
- `source` 当前主要区分 `pointCloud`、`fusionPreview`、`globalMap` 三条显示语义，联调时不要把它们混看成同一来源。

客户端 → 服务端（当前确认型消息）：

| type 字段 | 数据内容 | 作用 |
|-----------|---------|------|
| `pointCloudAck` | `{ sequence }` | 确认当前单帧点云序号已被前端接收，控制后续分片发送窗口 |
| `fusionPreviewAck` | `{ sequence }` | 确认当前融合预览序号已被前端接收 |

## 7. 数据库核心表

| 表 | 关键字段 | 管理 Service |
|----|---------|-------------|
| users | id, username, password_hash, role, created_at | AuthManager |
| material_records | id, pile_id, volume, weight, timestamp | MaterialHistoryManager |
| volume_records | id, pile_id, volume, timestamp | MaterialHistoryManager |
| inventory_snapshots | id, total_volume, total_weight, pile_count, timestamp | MaterialHistoryManager |
| config_entries | config_key, config_value | ConfigManager |
| features | type, enabled | HttpServer |

数据库自动建表：后端启动时 `DatabaseManager::initializeTables()` 自动 CREATE TABLE / ALTER TABLE ADD COLUMN / CREATE INDEX。

## 8. 配置体系

### 8.1 后端配置 (`config/config.ini`)

| Section | 关键配置项 | 说明 |
|---------|-----------|------|
| [database] | host/port/username/password/database | MySQL 连接 |
| [lidar] | ip/port/info_port | 雷达网络 |
| [lidar_calibration] | offset_x/y/z, roll/pitch/yaw_deg | 雷达外参 |
| [plc] | protocol/ip/port | Modbus TCP/RTU |
| [camera] | rtsp_url/onvif_url/username/password | 视频源 |
| [processing] | voxel_size/statistical_outlier_*/roi_*/ground_fitting | 点云算法 |
| [recording] | input_codec/save_days/segment_duration | 录像参数 |
| [system] | log_level/ntp_server/timezone | 系统设置 |

### 8.2 前端运行参数（通过 /api/config 管理）

后端 `GET /api/config/schema` 返回结构化 schema，前端 `RuntimeConfigView` 等新配置中心页面按域和分组展示。
写操作通过 `POST /api/config { items: [{key, value}] }` 批量提交；旧 `ConfigView.vue` 现仅保留迁移导航壳，不再承载编辑逻辑。

### 8.3 前端环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| VITE_DATA_SOURCE | backend | 数据源模式 |
| VITE_API_BASE_URL | /api | 后端 API 地址 |
| VITE_WS_URL | 自动推导 | WebSocket 地址 |
| VITE_HLS_URL | — | HLS 视频流地址 |

## 9. 认证与权限

- 认证方式：JWT (access_token + refresh_token)
- 角色：super_admin / admin / operator / viewer
- 前端 Token 刷新：401 时自动 `POST /api/auth/refresh`，失败才跳转登录页
- 并发去重：多个请求同时 401 时只刷新一次，其他排队等待

## 10. 待确认事项

| 项目 | 状态 | 备注 |
|------|------|------|
| ARM Debian 11 完整构建 | 待现场验证 | 脚本已就绪 |
| 真实 PLC 联调 | 待现场验证 | ModbusClient 已对接 V2.0 协议 |
| 真实摄像头 ONVIF PTZ | 待现场验证 | PtzControls 已就绪 |
| 真实称重设备接入 | 待现场验证 | ScaleManager/ScaleConfig 已就绪 |
| 盲区补偿参数调优 | 待现场验证 | 运行参数已暴露 |
| PlaybackView 历史轨迹 | 已完成 | `/api/monitor/trajectory` 已落地，前后端已对齐 |
| `/api/history/operations` 分页 | 待对齐 | 前端传 page/pageSize/sortBy 等 |
