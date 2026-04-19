# Point Cloud Angle Clip Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为单帧点云显示补齐 SDK FOV 显式控制和后端六向几何裁切配置，并部署到测试机验证。

**Architecture:** 把“是否由 SDK 默认 FOV 导致”与“正式业务裁切能力”拆成两层。SDK 层只负责 `SetAngleRange`，正式裁切只在 `WebSocketServer` 的单帧显示链对原始局部坐标点云做六向几何裁切。

**Tech Stack:** Qt/C++, PCL, Tanway SDK, Node test, ARM 远端构建部署脚本

---

### Task 1: 先写 failing tests

**Files:**
- Modify: `backend/tests/pcl_regression_tests.cpp`
- Modify: `frontend/tests/monitor-stream-contract.test.mjs`

- [x] 增加几何六向裁切单元测试
- [x] 运行回归测试或至少触发编译失败，确认新符号当前不存在
- [x] 增加单帧链/SDK FOV 合同测试
- [x] 运行合同测试，确认新增断言先失败

### Task 2: 实现通用六向裁切工具

**Files:**
- Modify: `backend/include/utils/Types.h`
- Modify: `backend/include/processing/pcl/PointCloudProcessingUtils.h`
- Modify: `backend/src/processing/pcl/PointCloudProcessingUtils.cpp`

- [x] 增加方向裁切配置结构
- [x] 实现轴枚举解析与默认值
- [x] 实现单点几何判定
- [x] 实现点云裁切函数
- [x] 跑回归测试，确认几何行为转绿

### Task 3: 接入配置读取与配置中心 schema

**Files:**
- Modify: `backend/src/core/ConfigManager.cpp`
- Modify: `backend/src/service/HttpServer.cpp`
- Modify: `config/config.ini`

- [x] 给 `SystemConfig` 增加 SDK FOV 和单帧方向裁切字段
- [x] 在 `ConfigManager` 读取/落盘这些字段
- [x] 在 `HttpServer` 运行时配置 schema 中暴露这些键
- [x] 给 `config.ini` 补默认值

### Task 4: 接入 SDK FOV 和单帧显示链

**Files:**
- Modify: `backend/src/drivers/lidar/LidarDriverSdk.cpp`
- Modify: `backend/src/service/WebSocketServer.cpp`

- [x] 在 `LidarDriverSdk::initialize()` 显式调用 `SetAngleRange`
- [x] 默认按“全角”接管 SDK 默认窄 FOV
- [x] 在 `prepareFrameDisplayPointCloud()` 接入六向裁切
- [x] 跑合同测试，确认 source-level 行为转绿

### Task 5: 构建、部署、验活

**Files:**
- Modify: `.codex/skills/arm-crosscompile-test/references/field-notes.md`

- [x] 本地跑相关测试
- [x] ARM 编译机构建
- [x] 部署到测试机
- [x] 验证后端服务、前端资源、雷达回调
- [x] 把新的部署事实回写到 `field-notes.md`
