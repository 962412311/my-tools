# Point Cloud Fusion And Display Rearchitecture Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在保持原始单帧点云稳定显示的前提下，引入段式融合链，使盘存/体积测量优先准确，监控和回放只消费轻量融合轮廓，并避免后台处理链再次拖死后端。

**Architecture:** 保留 `SDK -> WebSocket raw frame` 原始显示链，不再让融合链反压实时单帧显示；新增段式融合服务，按轨迹段/停稳后提交一次融合结果，使用段级 surface cells 作为 canonical representation，并把融合预览与测量输入从同一份 canonical cells 派生。

**Tech Stack:** Qt/C++, PCL, Tanway SDK, Vue/Pinia, Node test, ARM 远端构建部署脚本

---

### Task 1: 先用合同测试钉死新边界

**Files:**
- Modify: `frontend/tests/monitor-stream-contract.test.mjs`
- Modify: `backend/tests/pcl_regression_tests.cpp`

- [ ] **Step 1: 为“原始单帧链和融合链硬隔离”增加 source-level 合同断言**

  断言目标：
  - `Application` 不再把 `LidarDriver::pointCloudReceived` 默认接到旧逐帧重处理主链
  - 新增融合服务/协调器接管段式处理
  - `WebSocketServer` 同时消费原始单帧和融合预览两条流
  - 前端 store 明确存在 `raw frame` 与 `fusion preview` 两类点云状态

- [ ] **Step 2: 为监控页自动切换语义增加合同断言**

  断言目标：
  - 默认模式是 `auto`
  - 新段未提交时显示 raw frame
  - 段提交后切换到 fusion preview
  - 不允许用旧 fusion preview 冒充新的实时结果

- [ ] **Step 3: 运行合同测试，确认新增断言先失败**

  Run:

  ```bash
  rtk bash -lc 'cd /mnt/d/QtWorkData/GOGS/frontend && node --test tests/monitor-stream-contract.test.mjs'
  ```

  Expected:
  - FAIL
  - 失败点落在尚未实现的新融合服务/新前端状态字段上

- [ ] **Step 4: 为段级 canonical cells 增加最小回归测试**

  目标：
  - 相同 surface cell 的多点更新能合并命中统计
  - 停稳或 flush 后能生成稳定的 preview / measurement 输出
  - 关闭融合链时不再排队处理点云

- [ ] **Step 5: 运行新增回归测试，确认也先失败**

  Run:

  ```bash
  rtk bash -lc 'cd /mnt/d/QtWorkData/GOGS && ctest --test-dir build -R pcl_regression_tests'
  ```

  Expected:
  - 在当前本地没有完整 build 目录时，至少应确认新测试符号尚不存在或编译尚未接线

---

### Task 2: 引入段式融合服务和运行时配置

**Files:**
- Create: `backend/include/processing/pcl/FusionSegmentService.h`
- Create: `backend/src/processing/pcl/FusionSegmentService.cpp`
- Modify: `backend/include/utils/Types.h`
- Modify: `backend/src/core/ConfigManager.cpp`
- Modify: `backend/src/service/HttpServer.cpp`
- Modify: `backend/src/core/Application.cpp`
- Modify: `backend/CMakeLists.txt` 或对应构建清单

- [ ] **Step 1: 扩 `SystemConfig`，新增融合域配置**

  增加最小字段：
  - `fusionEnabled`
  - `fusionMeasurementCellSize`
  - `fusionForceCommitDistanceM`
  - `fusionForceCommitSeconds`
  - `fusionStationaryMinFrames`
  - `monitorAutoSwitchToFusion`

- [ ] **Step 2: 在 `ConfigManager` 读取/落盘这些字段**

  约束：
  - 与当前 `[processing]` 段兼容
  - 迁移期允许保留 `processing/enable_point_cloud_processing`
  - 新行为优先由 `fusion/*` 驱动

- [ ] **Step 3: 在 `HttpServer` schema 暴露新配置键**

  需要明确文案：
  - 原始单帧显示链
  - 段式融合链
  - 监控页自动切换

- [ ] **Step 4: 创建 `FusionSegmentService` 骨架**

  最小职责：
  - 接 raw frame
  - 读取最新位姿
  - 管理 open segment
  - 提供 `flush/stop/reset`
  - 发出 `fusionPreviewReady` / `measurementCloudReady` / `fusionDiagnosticsUpdated`

- [ ] **Step 5: 在 `Application` 中创建并接线 `FusionSegmentService`**

  目标：
  - `LidarDriver::pointCloudReceived -> FusionSegmentService`
  - `LidarDriver::pointCloudReceived -> WebSocketServer raw frame` 保持独立
  - 原始单帧链不依赖融合链

- [ ] **Step 6: 运行合同测试，确认配置和接线相关断言转绿**

  Run:

  ```bash
  rtk bash -lc 'cd /mnt/d/QtWorkData/GOGS/frontend && node --test tests/monitor-stream-contract.test.mjs'
  ```

  Expected:
  - 配置键和 Application 连接相关断言通过

---

### Task 3: 实现段级 canonical cells 和段提交流程

**Files:**
- Modify: `backend/include/processing/pcl/FusionSegmentService.h`
- Modify: `backend/src/processing/pcl/FusionSegmentService.cpp`
- Modify: `backend/src/processing/pcl/PointCloudProcessingUtils.cpp`（如需复用工具）
- Modify: `backend/tests/pcl_regression_tests.cpp`

- [ ] **Step 1: 在融合服务中定义段级 surface cell 数据结构**

  最小字段：
  - `centerX/centerY`
  - `zMean/zTop`
  - `intensityMean`
  - `hitCount/stableHitCount`
  - `lastUpdateTs`

- [ ] **Step 2: 实现世界坐标转换后的一次量化更新**

  规则：
  - 每个原始点只进入一次 canonical cell
  - 不缓存无限增长的大点云副本
  - 段内直接增量更新 cell

- [ ] **Step 3: 实现段关闭条件**

  至少包含：
  - 停稳
  - 强制距离阈值
  - 强制时间阈值
  - 显式 flush

- [ ] **Step 4: 在段提交时生成两份输出**

  输出：
  - `fusion preview cloud`
  - `measurement cloud`

  两者要求：
  - 同源于 canonical cells
  - 不再做第二次几何降采样

- [ ] **Step 5: 关闭旧逐帧重处理主路径**

  目标：
  - 默认不再依赖旧 `PointCloudProcessor` 逐帧分析做融合
  - `processing/enable_point_cloud_processing=false` 不应再是唯一稳定性开关
  - 即使 `fusion/enabled=true`，内存也不能线性飙升

- [ ] **Step 6: 运行新增回归测试，确认段式融合行为转绿**

  Run:

  ```bash
  rtk bash -lc 'cd /mnt/d/QtWorkData/GOGS/frontend && node --test tests/monitor-stream-contract.test.mjs'
  ```

  以及：

  ```bash
  rtk bash -lc 'cd /mnt/d/QtWorkData/GOGS && git diff --check'
  ```

---

### Task 4: 接入 WebSocket 融合预览流和前端自动切换

**Files:**
- Modify: `backend/include/service/WebSocketServer.h`
- Modify: `backend/src/service/WebSocketServer.cpp`
- Modify: `frontend/src/stores/system.js`
- Modify: `frontend/src/views/MonitorView.vue`
- Modify: `frontend/tests/monitor-stream-contract.test.mjs`

- [ ] **Step 1: 在 `WebSocketServer` 接入融合预览流**

  目标：
  - 保留现有 `pointCloud` raw frame 流
  - 新增 `fusionPreview` 流
  - 给 `fusionPreview` 独立 `sequence/meta/source`

- [ ] **Step 2: 前端 store 增加 fusion preview 状态**

  需要新增：
  - `fusionPreview`
  - `fusionPreviewMeta`
  - `monitorPointCloudMode = auto/raw/fusion`

- [ ] **Step 3: 实现监控页自动切换规则**

  规则：
  - 默认 `auto`
  - 有 open segment 时显示 raw
  - 新 fusion preview 到达后切到 fusion
  - 用户手动切换时不破坏自动模式状态机

- [ ] **Step 4: 运行前端合同测试，确认 auto-switch 语义转绿**

  Run:

  ```bash
  rtk bash -lc 'cd /mnt/d/QtWorkData/GOGS/frontend && node --test tests/monitor-stream-contract.test.mjs'
  ```

- [ ] **Step 5: 运行整套前端测试**

  Run:

  ```bash
  rtk bash -lc 'cd /mnt/d/QtWorkData/GOGS/frontend && node --test tests/*.test.mjs'
  ```

  Expected:
  - 全绿

---

### Task 5: ARM 部署、长稳验证、文档回写

**Files:**
- Modify: `.codex/skills/arm-crosscompile-test/references/field-notes.md`
- Modify: `DOC/点云显示与融合全链路梳理.md`
- Modify: `todo.md`

- [ ] **Step 1: 本地验证本轮相关测试**

  Run:

  ```bash
  rtk bash -lc 'cd /mnt/d/QtWorkData/GOGS/frontend && node --test tests/*.test.mjs'
  ```

  和：

  ```bash
  rtk bash -lc 'cd /mnt/d/QtWorkData/GOGS && git diff --check'
  ```

- [ ] **Step 2: ARM 编译机重新构建后端**

  Run:

  ```bash
  rtk bash -lc 'cd /mnt/d/QtWorkData/GOGS && rsync -a --delete --exclude ".git" ./ jamin@192.168.1.118:/home/jamin/qt/GrabInventorySystem/ && ssh jamin@192.168.1.118 "set -e; rm -f /home/jamin/qt/GrabInventorySystem_backend/build/arm-gcc/GrabSystem; cd /home/jamin/qt/GrabInventorySystem; onebuild_GOGS_backend_self.sh; sha256sum /home/jamin/qt/GrabInventorySystem_backend/build/arm-gcc/GrabSystem"'
  ```

- [ ] **Step 3: 部署到测试机并验活**

  Run:

  ```bash
  rtk bash -lc 'cd /mnt/d/QtWorkData/GOGS && bash scripts/arm/deploy_backend.sh && bash scripts/arm/verify_remote.sh'
  ```

- [ ] **Step 4: 长稳观测**

  目标：
  - RSS 不再出现分钟级 GB 飙升
  - 原始单帧仍持续广播
  - 段提交后出现 fusion preview
  - 前端监控页不再因融合链拖死而断连

- [ ] **Step 5: 回写现场事实和链路文档**

  必须记录：
  - 新配置键
  - 新 WebSocket 流
  - 监控页自动切换语义
  - 稳定性观测结果

---

### Task 6: 收尾 review

**Files:**
- Review only

- [ ] **Step 1: 逐条对照 spec**

  检查：
  - 双链硬隔离
  - 测量优先
  - 段式提交
  - 一次几何量化
  - 监控页自动切 fusion

- [ ] **Step 2: 运行最终验证**

  Run:

  ```bash
  rtk bash -lc 'cd /mnt/d/QtWorkData/GOGS/frontend && node --test tests/*.test.mjs'
  ```

  以及：

  ```bash
  rtk bash -lc 'cd /mnt/d/QtWorkData/GOGS && git diff --check'
  ```

- [ ] **Step 3: 准备最终代码 review**

  输出：
  - 关键行为变化
  - 风险点
  - 尚未覆盖的现场验证项
