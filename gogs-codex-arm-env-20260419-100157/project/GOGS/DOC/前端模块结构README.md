# 前端模块结构 README

## 目标

这份文档用于说明前端当前的模块划分、页面职责、状态管理和数据流，方便后续继续模块化开发时知道代码应该落在哪里。

这份文档不讲视觉风格，重点讲结构。

补充入口：

- 如果是新会话或回归维护，先看 [GOGS RTK（快速上手包）](../docs/gogs-rtk.md)
- 当前前端整体验证优先使用 `rtk npm --prefix frontend run build` 和 `rtk npm --prefix frontend test`
- 如果只发测试机前端，优先用 `rtk bash scripts/arm/deploy_frontend.sh`

## 前端主线概览

当前前端是一个基于 `Vue 3 + Vite + Pinia + Element Plus` 的独立静态站点。

核心目录：

- `frontend/src/views`
- `frontend/src/components`
- `frontend/src/stores`
- `frontend/src/services`
- `frontend/src/router`
- `frontend/src/styles`
- `frontend/src/utils`

## 分层结构

当前可以把前端分成五层：

1. 路由与页面壳层
2. 页面视图层
3. 公共组件层
4. 服务与接口层
5. 状态与主题层

```text
router
  ->
LayoutView / LoginView
  ->
业务页面 views
  ->
components
  ->
services/api.js + stores/*
  ->
backend http / websocket
```

## 路由与页面壳层

核心文件：

- `frontend/src/router/index.js`
- `frontend/src/views/LayoutView.vue`
- `frontend/src/views/LoginView.vue`

### 路由职责

`router/index.js` 当前负责：

- 定义页面路由
- 配置页面 meta
- 做登录态守卫
- 做管理员 / 超级管理员权限守卫

当前主要页面入口：

- `Dashboard`
- `Monitor`
- `Inventory`
- `History`
- `Playback`
- `Remote`
- `Config`
- `Features`

当前主线补充：

- 新配置中心 `views/config/*` 才是当前配置编辑主线
- 旧 `ConfigView.vue` 已退化为只读迁移壳，不再作为新增能力入口

### 布局壳职责

`LayoutView.vue` 负责：

- 顶部栏
- 侧边导航
- 页面容器
- 用户菜单、主题切换、状态区挂载

原则上：

- 公共导航和壳层逻辑放这里
- 具体业务交互不要继续堆进这里

## 页面视图层

`frontend/src/views` 当前对应一页一职责：

- `DashboardView.vue`
  - 首页概览、系统状态、核心统计
- `MonitorView.vue`
  - 实时监控、视频、点云、截图、录像、批量盘点、边界导入导出、视角预设
- `InventoryView.vue`
  - 库存快照、对比、详情、报表导出
- `HistoryView.vue`
  - 物料操作历史、筛选、统计
- `PlaybackView.vue`
  - 点云和视频历史回放，展示录像单文件/分段语义、完成状态和回放列表元数据
- `RemoteOperationView.vue`
  - 远控会话、控制按钮、作业模式、状态展示
- `views/config/*`
  - 新配置中心主线，覆盖作业运维、设备通信、业务配置和高级维护
- `ConfigView.vue`
  - 已退路由的遗留配置大页，仅作历史兼容参考
- `FeatureSwitchView.vue`
  - 功能开关管理
- `UserManagementView.vue`
  - 用户管理（挂在配置中心高级维护域）
- `ForbiddenView.vue` / `NotFoundView.vue` / `TestView.vue`
  - 状态页与测试页

当前页面层的一个现实情况是：

- `MonitorView.vue` 和 `RemoteOperationView.vue` 承担了较多流程编排，后续如果继续做功能增强，优先考虑抽 composable 或子组件，不要继续无界膨胀。
- 新配置中心 `views/config/*` 已经承接当前配置主线；旧 `ConfigView.vue` 仍保留历史实现，只能作为迁移参考，后续不再继续承载新能力。

## 公共组件层

`frontend/src/components` 当前承载：

- 顶部状态类组件
- 面包屑
- 视频播放器
- 高低点面板
- 数据清理和管理类弹窗
- 共用业务卡片或管理面板

这一层的职责应该是：

- 封装可复用 UI 单元
- 屏蔽页面重复结构

不应该在这里继续堆：

- 页面专属的业务流程
- 大量接口编排

## 服务与接口层

核心文件：

- `frontend/src/services/api.js`

当前这里承担：

- axios 实例创建
- 错误标准化
- REST API 封装
- WebSocket 创建入口

已经封装的主线包括：

- 系统状态
- 料堆与物料类型
- 历史与库存快照
- 视频 PTZ / 预置位 / 抓图
- 配置
- 远控控制

当前建议继续保持这个边界：

- 页面不要直接散落写 `fetch('/api/...')`
- 新接口优先先加到 `api.js`

## 状态与主题层

`frontend/src/stores` 当前主要有四类状态：

- `user.js`
  - 登录态、token、用户信息、角色权限
- `system.js`
  - WebSocket/HTTP 连接状态
  - 点云、地图、位姿、最高点、体积记录、处理诊断
- `theme.js`
  - 明暗主题与跟随系统
- `featureSwitches.js`
  - 功能开关列表和能力判断

### 当前状态边界

建议继续保持：

- 用户权限放 `user store`
- 实时系统状态放 `system store`
- UI 主题放 `theme store`
- 业务能力开关放 `featureSwitches store`

不要继续把这些混到页面本地状态里。

## 实时数据流

当前实时数据主要来自两条主线：

### 1. WebSocket 实时链

`system store` 负责：

- 建立 WebSocket
- 收到消息后分发到：
  - `pointCloud`
  - `globalMap`
  - `gantryPose`
  - `highestPoint`
  - `volumeRecords`
  - `processingDiagnostics`

这是监控页和部分仪表页的实时数据基础。

### 2. HTTP 拉取链

页面通过 `api.js` 主动拉取：

- 历史记录
- 库存快照
- 配置
- 料堆和物料类型
- 视频 PTZ / 控制接口

这条链适合：

- 列表查询
- 配置读写
- 显式操作动作

## 页面与后端边界

当前建议继续遵守这些边界：

- 页面负责交互流程和展示
- `api.js` 负责接口封装
- `store` 负责跨页面共享状态
- 后端负责真实业务语义和设备能力

不要继续走回头路：

- 不要在页面里保留假数据回退
- 不要在页面里硬编码“假成功”动作
- 不要把设备协议细节搬到前端

## 当前结构上的重点页面

### `MonitorView.vue`

这是当前最复杂的页面之一，既有：

- 视频
- 点云
- 实时状态
- 云台控制
- 视角预设
- 批量盘点
- 边界导入导出

后续如果继续增强，优先考虑拆这些方向：

- 视频与 PTZ 控制块
- 搜索与批量盘点块
- 边界导入导出块
- 视角预设与 3D 工具块

### `RemoteOperationView.vue`

这是控制链集中页，后续如果继续增强，优先考虑把：

- 控制面板
- 状态面板
- 会话申请弹窗

做结构性拆分。

## 当前文档对应关系

前端如果涉及下列能力，请优先看对应文档：

- 视频与 ONVIF：
  - `DOC/视频链路与ONVIFREADME.md`
- PLC 控制：
  - `DOC/PLC控制链路README.md`
- 后端服务分层：
  - `DOC/后端服务架构README.md`
- 点云算法：
  - `DOC/点云算法设计README.md`

## 后续建议

1. 继续把 `MonitorView.vue` 的大块流程抽成 composable 或子组件
2. 继续减少页面直接碰底层浏览器 API 的范围，优先通过组件或服务层隔离
3. 后续如果继续增加业务模块，优先补模块 README，再动实现

## 代码入口

- `frontend/src/router/index.js`
- `frontend/src/views/LayoutView.vue`
- `frontend/src/views/MonitorView.vue`
- `frontend/src/views/RemoteOperationView.vue`
- `frontend/src/services/api.js`
- `frontend/src/stores/system.js`
- `frontend/src/stores/user.js`
- `frontend/src/stores/theme.js`
- `frontend/src/stores/featureSwitches.js`

## 推荐验证入口

```bash
rtk ./scripts/frontend-dev.sh
rtk npm --prefix frontend run build
rtk npm --prefix frontend test
rtk npm --prefix frontend run test:browser:install
rtk npm --prefix frontend run test:browser -- tests/browser/monitor-browser-smoke.spec.mjs --config=playwright.config.mjs
rtk bash scripts/arm/deploy_frontend.sh
```
