# 点云角度裁切配置设计

## 目标

把“当前监控页单帧点云像被从错误方向裁掉一扇”拆成两层能力：

1. SDK FOV 诊断层  
用于快速确认问题是否来自 Tanway SDK 默认 `30~150°` 水平视场裁切。

2. 单帧显示六向裁切层  
用于在后端配置里控制单帧显示的几何裁切方向、范围、偏移和开关，不再依赖 SDK 对水平角方向的定义。

## 约束

- 单帧显示链继续保持“原始 SDK 单帧 + 降采样”为主，不叠加旧处理链。
- 为了验证根因，SDK 层默认应放开到近全角。
- 正式裁切能力必须支持：
  - `+X / -X / +Y / -Y / +Z / -Z`
  - 开关关闭
  - 角度范围
  - 方向偏移
  - 反向取补

## 设计

### 1. SDK FOV 配置

新增配置：

- `tanway_sdk/launch/fov_enabled`
- `tanway_sdk/launch/fov_min_deg`
- `tanway_sdk/launch/fov_max_deg`

行为：

- `fov_enabled=false` 时，启动后显式调用 SDK `SetAngleRange(0.01, 360.0)`，避免继续吃 SDK 默认 `30~150°`。
- `fov_enabled=true` 时，按配置的 `min/max` 调用 `SetAngleRange()`。

这层只用于 SDK 水平视场诊断和兼容，不承载正式“六向裁切”语义。

### 2. 单帧显示六向裁切配置

新增配置：

- `processing/display_frame_directional_clip_enabled`
- `processing/display_frame_directional_clip_axis`
- `processing/display_frame_directional_clip_half_angle_deg`
- `processing/display_frame_directional_clip_angle_offset_deg`
- `processing/display_frame_directional_clip_invert`

其中：

- `axis` 取值：`+X/-X/+Y/-Y/+Z/-Z`
- `enabled=false` 表示关闭裁切
- `half_angle_deg` 表示以主轴为中心的半角
- `angle_offset_deg` 表示绕主轴正交平面的偏移修正
- `invert=true` 表示取补集

### 3. 裁切落点

正式六向裁切只放在监控页单帧显示链：

- `WebSocketServer::prepareFrameDisplayPointCloud()`

顺序：

1. 复制有限点
2. 可选执行六向几何裁切
3. 执行体素降采样

这样可以确保：

- 监控页单帧看到的是原始雷达局部坐标下的裁切结果
- 不把世界坐标、PLC 位姿、ROI、ring filter 混进来

## 测试

### 回归测试

在 `backend/tests/pcl_regression_tests.cpp` 增加：

- 六向裁切基础行为
- `invert` 取补行为
- 关闭裁切保持原样

### 合同测试

在 `frontend/tests/monitor-stream-contract.test.mjs` 增加：

- `LidarDriverSdk.cpp` 已显式接管 `SetAngleRange`
- `WebSocketServer.cpp` 已消费新的单帧方向裁切配置

## 非目标

- 这轮不把六向裁切接到 `globalMap` 和处理融合链
- 不改前端交互页去可视化编辑该配置
- 不尝试在浏览器里自动判定“应该裁哪一侧”
