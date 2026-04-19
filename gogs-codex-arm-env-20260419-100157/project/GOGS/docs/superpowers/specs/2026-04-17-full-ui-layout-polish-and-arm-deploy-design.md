# 全界面布局收口与 ARM 发布设计文档

日期：2026-04-17
范围：`frontend/src/views/**`、共享布局组件、相关契约测试、`scripts/arm/**` 复用发布链路
状态：已确认，进入实施

## 1. 目标

本轮目标分两部分：

1. 把当前前端所有主界面的布局细节问题统一收口，保证页面骨架、间距、断点、信息层级和折叠行为符合现有全局设计规范。
2. 在本地完成可发布验证后，将完整产物部署到 ARM 测试机，并以脚本化、强判定方式完成验活。

## 2. 约束

- 不改后端 API 契约。
- 不重做全站视觉语言，继续沿用现有工业控制台深色体系。
- 优先复用现有共享骨架：`PageHeader`、`SectionCard`、`WorkbenchToolbar`、`ConfigPageShell`。
- ARM 部署优先复用 `scripts/arm/` 阶段化脚本，不另起一套临时命令链。
- 所有完成声明必须基于 fresh verification。

## 3. 事实基础

### 3.1 全局设计规范

当前前端设计规范已明确：

- 深色优先，高信息密度，但层次必须清楚。
- 间距采用统一 token，卡片内边距以 `20px-24px` 为主。
- 命令中心类页面采用：`PageHeader + 状态摘要/工具条 + 主任务区 + 辅助区`
- 工作台类页面采用：`PageHeader + WorkbenchToolbar + SectionCard/详情区`
- 断点至少覆盖：大屏、平板、小屏。

规范来源：

- `frontend/docs/global-design-system.md`
- `DOC/前端UI设计需求文档.md`
- `frontend/docs/frontend-architecture.md`

### 3.2 当前问题类型

当前问题不是单页 bug，而是多页布局模型漂移：

- 有些页面仍保留自定义头部，没有回到统一 `PageHeader`。
- 某些工具条和筛选条仍存在固定宽度栅格，窄屏下易挤压。
- 命令中心类页面的主副区高度、卡片密度、断点切换口径不一致。
- 一些工作台页虽然已接入共享组件，但页头、摘要、侧栏、表格和附加说明区之间仍有间距与栅格漂移。
- Layout shell 与边界页也需要做最后一轮视觉和响应式收口。

## 4. 页面簇划分

### 4.1 共享骨架层

优先收口：

- `frontend/src/components/layout/PageHeader.vue`
- `frontend/src/components/layout/SectionCard.vue`
- `frontend/src/components/layout/WorkbenchToolbar.vue`
- `frontend/src/components/config-center/ConfigPageShell.vue`
- `frontend/src/views/LayoutView.vue`

这层负责统一：

- 页头和动作区换行规则
- 工具条三段区块的密度和包裹行为
- 卡片头/体间距
- 页面内容容器的最大宽度和底部留白
- 命令中心页与工作台页的统一入口姿态

### 4.2 命令中心页

页面：

- `DashboardView.vue`
- `MonitorView.vue`
- `PlaybackView.vue`
- `RemoteOperationView.vue`

目标：

- 统一页头、摘要条、主副布局、下沉信息区的层级表达。
- 清理固定宽度和局部自定义布局造成的拥挤问题。
- 确保宽屏、笔记本、窄屏下的主任务区不被压坏。

### 4.3 工作台页

页面：

- `InventoryView.vue`
- `HistoryView.vue`
- `FeatureSwitchView.vue`
- `UserManagementView.vue`
- `views/config/**`

目标：

- 统一为 `PageHeader/ConfigPageShell + WorkbenchToolbar + SectionCard` 口径。
- 修筛选区、摘要区、表格主区、辅助说明区的对齐和换行。
- 清理局部自定义 spacing 与边界状态。

### 4.4 边界页

页面：

- `LoginView.vue`
- `ForbiddenView.vue`
- `NotFoundView.vue`

目标：

- 确保与主视觉体系一致。
- 修正移动端和小屏下的边距、对齐和信息层级。

## 5. 本轮布局策略

### 5.1 共享优先，局部补齐

本轮不做大规模重构拆分，优先通过共享骨架收口通用行为，再补页面局部问题。这样可以避免：

- 每页重复修同一类问题
- 后续回归时重新漂移
- ARM 上部署一版后，页面间表现不一致

### 5.2 命令中心页统一规则

- `Dashboard` 收回共享页头和统一卡片语言。
- `Monitor` 保持双主舞台方案，但继续压实尺寸、断点和轻栏密度。
- `Playback` 清除固定宽度筛选栅格，保证筛选条、回放主区、详情区在 1024px 左右仍稳定。
- `RemoteOperation` 统一主副舞台高度与右栏密度，避免局部控件过大、页面上下边不齐。

### 5.3 工作台页统一规则

- 主工具条允许纵向堆叠，但不允许出现“局部区块单独漂移”的断裂感。
- 表格区优先保主内容宽度，说明区和辅助区在断点下移或折叠。
- 摘要 pills、tag、alert、说明卡统一密度和行高，不再各页自定义一套。

## 6. 测试与发布策略

### 6.1 本地验证

至少执行：

- 相关 node 契约测试
- `frontend` 构建
- Playwright 浏览器 smoke

### 6.2 ARM 发布

固定采用阶段化流程：

1. `preflight`
2. `build_backend_remote`
3. `deploy_backend`
4. `deploy_frontend`
5. `verify_remote`

优先入口：

- `rtk bash scripts/arm/pipeline.sh`

如只需重复发布前端：

- `rtk bash scripts/arm/deploy_frontend.sh`
- `rtk bash scripts/arm/verify_remote.sh`

### 6.3 目标环境口径

运行目标以：

- `.codex/skills/arm-crosscompile-test/references/runtime-targets.local.yml`

为准，而不是模板文件。

当前确认目标：

- 编译机：`jamin@192.168.1.118`
- 测试机：`root@100.105.175.44`
- 运行根：`/userdata/GOGS`
- 后端服务：`gogs-backend.service`
- 前端服务：`nginx`

## 7. 完成标准

本轮完成必须同时满足：

1. 主界面布局符合全局设计规范，没有明显固定宽度、断点错位、卡片挤压、信息层级混乱问题。
2. 本地相关测试、构建、浏览器 smoke 通过。
3. ARM 测试机完成部署，且远端服务、页面与关键接口验活通过。
4. 必要文档与测试同步更新，避免后续回归。
