# 全界面布局收口与 ARM 发布 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 统一修复全站主界面的布局细节问题，完成本地验证后将最新产物完整部署到 ARM 测试机并验活。

**Architecture:** 先收口共享布局骨架，再按页面簇修复命令中心页、工作台页和边界页；验证通过后复用 `scripts/arm/` 现有阶段化脚本完成 ARM 部署与强验活。

**Tech Stack:** Vue 3 SFC, Element Plus, existing layout primitives, Node test runner, Playwright, Vite, repository ARM deployment scripts.

---

### Task 1: 固定共享布局骨架

**Files:**
- Modify: `frontend/src/components/layout/PageHeader.vue`
- Modify: `frontend/src/components/layout/SectionCard.vue`
- Modify: `frontend/src/components/layout/WorkbenchToolbar.vue`
- Modify: `frontend/src/components/config-center/ConfigPageShell.vue`
- Modify: `frontend/src/views/LayoutView.vue`
- Test: `frontend/tests/layout-polish-contract.test.mjs`
- Test: `frontend/tests/ui-style-contract.test.mjs`

- [ ] 审查共享组件当前间距、换行、断点和对齐行为，并补齐契约测试期望。
- [ ] 先写或更新会失败的布局契约断言，覆盖页头、工具条、卡片和壳层的统一行为。
- [ ] 修改共享组件样式与壳层容器，使命令中心页与工作台页的共性行为收口到同一套规则。
- [ ] 运行共享布局相关测试，确认新契约通过。

### Task 2: 修复命令中心页布局

**Files:**
- Modify: `frontend/src/views/DashboardView.vue`
- Modify: `frontend/src/views/MonitorView.vue`
- Modify: `frontend/src/views/PlaybackView.vue`
- Modify: `frontend/src/views/RemoteOperationView.vue`
- Modify: `frontend/src/components/monitor/CameraPanel.vue`
- Modify: `frontend/src/components/monitor/MonitorLightRail.vue`
- Modify: `frontend/src/components/monitor/MonitorWorkbenchPanels.vue`
- Test: `frontend/tests/monitor-split-layout-contract.test.mjs`
- Test: `frontend/tests/monitor-layout-workbench-contract.test.mjs`
- Test: `frontend/tests/layout-polish-contract.test.mjs`

- [ ] 收口首页页头、主副区和洞察网格，避免继续使用偏离共享骨架的自定义头部与局部卡片语义。
- [ ] 继续统一监控页 split 布局的尺寸、轻栏和下沉区细节，确保视频/点云/轻栏高度与断点一致。
- [ ] 修复回放页固定筛选栅格和主副区拥挤问题，使其在 1024px 级别仍稳定可用。
- [ ] 修复远程操作页主副舞台高度、右栏控件密度和窄屏堆叠规则。
- [ ] 运行命令中心页相关契约测试，确认布局没有回归。

### Task 3: 修复工作台页与边界页

**Files:**
- Modify: `frontend/src/views/InventoryView.vue`
- Modify: `frontend/src/views/HistoryView.vue`
- Modify: `frontend/src/views/FeatureSwitchView.vue`
- Modify: `frontend/src/views/UserManagementView.vue`
- Modify: `frontend/src/views/LoginView.vue`
- Modify: `frontend/src/views/ForbiddenView.vue`
- Modify: `frontend/src/views/NotFoundView.vue`
- Modify: `frontend/src/views/config/*.vue`
- Test: `frontend/tests/interface-alignment-contract.test.mjs`
- Test: `frontend/tests/config-center-page-contract.test.mjs`
- Test: `frontend/tests/config-center-domain-contract.test.mjs`

- [ ] 统一工作台页的工具条、表格主区、说明区和断点下移行为。
- [ ] 对照配置中心既有设计文档，修掉配置页中残留的局部布局漂移。
- [ ] 修复登录页和边界页的小屏间距、信息层级和视觉一致性问题。
- [ ] 运行相关契约测试，确认工作台页和配置中心没有被破坏。

### Task 4: 本地完整验证

**Files:**
- Modify: `frontend/tests/*.mjs`（按需）
- Modify: `frontend/tests/browser/monitor-browser-smoke.spec.mjs`（按需）

- [ ] 运行本轮涉及的 node 契约测试并检查输出。
- [ ] 运行 `frontend` 构建并确认产物成功生成。
- [ ] 运行 Playwright 浏览器 smoke，确认首页、监控页、回放页主链路正常。
- [ ] 如验证失败，只修最小确定原因后重跑对应阶段。

### Task 5: ARM 部署与远端验活

**Files:**
- Reuse: `scripts/arm/preflight.sh`
- Reuse: `scripts/arm/build_backend_remote.sh`
- Reuse: `scripts/arm/deploy_backend.sh`
- Reuse: `scripts/arm/deploy_frontend.sh`
- Reuse: `scripts/arm/verify_remote.sh`
- Reference: `.codex/skills/arm-crosscompile-test/references/runtime-targets.local.yml`

- [ ] 先检查本地提交状态、目标机配置和阶段脚本口径，确认使用 `runtime-targets.local.yml`。
- [ ] 执行阶段化 ARM 发布流程，优先使用 `rtk bash scripts/arm/pipeline.sh`；若只需要重复发布前端，则使用 `deploy_frontend.sh + verify_remote.sh`。
- [ ] 检查远端 `gogs-backend.service`、运行中 SHA、前端静态资源、HLS、PTZ ONVIF 和雷达 callback 证据。
- [ ] 仅在所有强判定都成立后，才报告 ARM 测试机发布完成。

### Task 6: 文档同步与收尾

**Files:**
- Modify: `README.md`（按需）
- Modify: `docs/gogs-rtk.md`（按需）
- Modify: `frontend/docs/frontend-architecture.md`（按需）
- Modify: 其他受影响文档（按需）

- [ ] 如果共享骨架或部署/验证入口发生变化，同步更新开发文档和现场说明。
- [ ] 运行针对修改文件的 `git diff --check`，避免格式性回归。
- [ ] 汇总本地验证与 ARM 验活证据，再做最终结论。
