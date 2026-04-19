# 前端优化 TODO 清单

> 创建日期：2026-04-03
> 状态标记：[x] 已完成 / [ ] 待处理 / [~] 进行中

补充说明：
- 这份清单当前主要承担“历史推进记录 + 剩余现场验证项”两种角色，不再作为唯一现行任务分发表。
- 现行入口优先看 `docs/gogs-rtk.md`、`frontend/docs/frontend-architecture.md` 和项目根 `todo.md`。
- `阶段 1` 到 `阶段 9` 中涉及旧 `ConfigView.vue` 和大页拆分的条目，默认视为历史推进记录；当前未勾选项只有在仍与现行页面相关时才保留为待办。

---

## 阶段 1：基础清理（已完成）

- [x] 清理 LoginView.vue CSS 重复块（~230 行）
- [x] 清理 DashboardView.vue CSS 重复块（~80 行）
- [x] 清理 MonitorView.vue CSS 重复块（~35 行）
- [x] 移除所有 scoped `@import theme.css`（24 个文件）
- [x] 提取 DiagnosticsPanel + RescanActions 子组件（MonitorView -750 行）

---

## 阶段 2：界面设计优化（已完成）

### MonitorView（实时监控）
- [x] 工具栏精简：移除录像编码/插件/前提标签，仅保留 REC 状态标签
- [x] 底部区域改为 8:16 比例（坐标:日志），日志占 2/3
- [x] 日志容器添加自动滚动
- [x] 货场视图修复硬编码坐标映射，改为使用 mapYardPointToCanvas
- [x] PTZ 状态标签精简：合并 RTSP/ONVIF 为单标签
- [x] 移除所有装饰性 CSS 动画（scanline/pulse/glow/float/fadeInUp）
- [x] 移除 hover 位移效果（translateY/translateX/scale），改为简单背景变化
- [x] 移除图标外发光伪元素（::before blur effect）
- [x] 移除快捷按钮光效伪元素
- [x] 移除点云标记/标注标记 pulse 动画，改为静态阴影
- [x] 移除货场视图 emoji（📍🚛），改为 CSS 图标点

### LoginView（登录页）
- [x] 移除 3 个渐变球体 HTML 元素
- [x] 移除所有球体相关 CSS（.gradient-orb/.orb-1/2/3）
- [x] 移除 @keyframes 动画（orbPulse/float/pulse）
- [x] 移除 backdrop-filter blur，改为实色半透明背景
- [x] 移除 brand-logo 悬浮动效和 ::before 发光层

### LayoutView（框架布局）
- [x] 侧边栏宽度 260px -> 220px，折叠态 64px -> 56px
- [x] Header 高度 72px -> 56px
- [x] 移除 header backdrop-filter
- [x] 中文主标题、导航分组和顶部上下文切换为统一的工业控制台字体系与间距

### 全局样式
- [x] 字体替换：外网字体依赖 -> 系统优先中文工业字体栈
- [x] 按钮 / 标签 / Tabs / RadioButton / Segmented 的中文居中规则统一收口到全局基础样式

---

## 阶段 3：已完成

### MonitorView 进一步优化
- [x] 诊断面板 30+ 项按功能分组（基础处理/标定/补扫/盲区/轨迹窗口）
- [x] 提取 PtzControls 子组件（MonitorView -200 行）

### DashboardView
- [x] 修复 ECharts tooltip/axis 中 CSS 变量字符串无法解析问题（改用 cssVar() 函数）
- [x] 精简 hover 效果（stat-card/action-item/record-item 移除 translateY/rotate/blur 伪元素）

### LayoutView
- [x] 移除侧边栏 ::before 装饰渐变光效
- [x] 移除主内容区 ::before 网格背景装饰
- [x] 精简菜单项 hover 效果（移除 translateX、scale、drop-shadow）
- [x] 精简折叠按钮 hover（移除 scale、box-shadow）
- [x] 移除激活图标 drop-shadow 发光效果

### 全局
- [x] 清理生产代码中 console.log 残留（6 个文件，16 处）
- [x] 构建配置：esbuild `drop: ['console', 'debugger']` 双层配置，生产包零 console 输出（已验证）
- [x] DiagnosticsPanel 诊断值移除 text-shadow 发光效果
- [x] DiagnosticsPanel hover 移除 translateY 和 box-shadow

---

## 阶段 4：全局装饰清理（已完成）

### 装饰性动画移除
- [x] DashboardView: scanline 扫描线动画、pulse 呼吸动画、fadeIn 入场动画
- [x] InventoryView: fadeIn 入场动画
- [x] HistoryView: fadeIn 入场动画
- [x] RemoteOperationView: pulse 标记动画、bounce 方向指示器动画
- [x] 保留: LoginView fadeInUp（登录页入场合理）、VideoPlayer rotate（加载旋转）、SystemStatus shake-error（错误反馈）

### text-shadow 发光效果移除
- [x] DashboardView: .info-item .value.highlight
- [x] InventoryView: .compare-value.up/.down
- [x] HistoryView: .header-stat-item .stat-value
- [x] MonitorView: .coord-value.highlight
- [x] ConfigView: 状态指示值

### hover 变换精简
- [x] InventoryView: stat-card、stat-icon、compare-stat、report-type-card、header-right 按钮、resource-actions 按钮
- [x] HistoryView: header-stat-item、filter-actions 按钮
- [x] LoginView: login-button hover/active
- [x] RemoteOperationView: direction-indicator
- [x] 8 个公共组件: UserMenu、FeatureList、PileManager、DataManager、SystemStatus、ConnectionStatus、ThemeSwitch、HighLowPointPanel

### backdrop-filter blur 移除
- [x] MonitorView: 6 处（摄像头名称/时间戳、标注标签、点云信息、货场图例、坐标面板）
- [x] FeatureSwitchView: 1 处
- [x] PlaybackView: 1 处
- [x] VideoPlayer 组件: 2 处

---

## 阶段 5：功能改进（大部分已完成，旧 ConfigView 项已归档）

### 2026-04-16 非点云收口
- [x] 用户菜单移除“个人中心开发中”占位，管理员直接进入“用户与权限 / 配置中心”
- [x] 同步 `docs/frontend-backend-interface-alignment.md`、`frontend/docs/frontend-architecture.md`、`DOC/前端模块结构README.md` 的新配置中心主线路径
- [x] 回写 Playback 历史轨迹接口已落地的事实，移除过期“待后端提供 `/api/monitor/trajectory`”描述
- [x] 将旧 `ConfigView.vue` 明确记为遗留实现，不再作为当前配置主线口径
- [x] 将海康视频基线与 Tanway 官方运行分组说明迁入 `RuntimeConfigView`，收口旧 `ConfigView.vue` 的运行参数知识
- [x] 将高级维护域的“维护操作”入口收紧为超级管理员可见/可达，避免管理员看到不可执行入口
- [x] 将 `AdvancedHomeView` 的维护状态加载限制为超级管理员，避免普通管理员进入高级维护总览时触发 403
- [x] 将旧 `ConfigView.vue` 裁剪为只读迁移壳，并删除失效的 `scripts/check-config-view-bindings.js`

### MonitorView
- [x] Three.js 轨迹改为真实数据驱动（`trajectoryPoints` 世界坐标 → Three.js Line，实时增量更新）
- [x] 智能标注层从硬编码 `top:30% left:40%` 改为底部状态栏（显示最高点 Z 值和料堆名称，无需相机标定参数）
- [x] highestPointMarker 从 HTML overlay 改为 Three.js 场景内标记（球体+环+Sprite标签+竖线，随点云自然旋转缩放）
- [x] 提取 YardView 子组件（`components/monitor/YardView.vue`，~553 行，MonitorView 从 4568→4131 行）
- [x] 将 `VideoPanel` 进一步拆分任务降级为历史优化项（props/handlers 耦合过高，当前不作为现行阻塞）

### PlaybackView
- [x] 移除 Math.sin/cos 假轨迹数据，并切换到真实历史轨迹接口链路

### DashboardView & HistoryView
- [x] ECharts 主题切换自动重绘（MutationObserver 监听 `data-theme` 变化 → 重新调用 `updateCharts()`）
- [x] InventoryView 和 PlaybackView 也添加了主题切换监听
- [x] KPI 卡片布局改为 CSS Grid 自适应网格（`grid-template-columns: repeat(auto-fill, minmax(220px, 1fr))`，告别固定 6 列）

### ConfigView（历史记录）
- [x] 提取 AlgorithmConfig 子组件（`components/config/AlgorithmConfig.vue`，~867 行，算法调参预设/参数说明）
- [x] 提取 DataManageConfig 子组件（`components/config/DataManageConfig.vue`，~280 行，物料类型 CRUD）
- [x] 提取 InventoryScheduleConfig 子组件（`components/config/InventoryScheduleConfig.vue`，~346 行，盘存周期管理）
- [x] 将旧 `ConfigView` 的扩展配置/系统概览/称重设备继续拆分任务归档（旧页已退化为只读迁移壳，不再继续投入）

---

---

## 阶段 6：深度装饰清理（已完成）

### MonitorView
- [x] 移除 toolbar-card ::before 装饰渐变光效
- [x] 移除 pointcloud-container ::before radial-gradient 装饰
- [x] 移除 yard-container ::before radial-gradient 装饰
- [x] 简化 pointcloud-container: 移除 inset box-shadow、渐变背景 → 实色背景
- [x] 简化 annotation-marker: 双层 glow box-shadow → 单层 ring
- [x] 简化 lowest-point-marker: glow box-shadow → subtle shadow
- [x] 简化 toolbar-card hover: shadow-md → shadow-sm

### PlaybackView
- [x] 移除 video-container scanline ::after 动画
- [x] 移除 video-container inset box-shadow
- [x] 移除 video-container:hover 外发光 box-shadow
- [x] 移除 pointcloud-container:hover 外发光 box-shadow
- [x] 移除 pointcloud-container inset box-shadow

### ConfigView（历史记录）
- [x] 移除全部 hover translateY(-1px/-2px/-3px) 变换（8 处）

### 全局注释清理
- [x] 移除 83 个 `/* ====== section ====== */` 分隔注释（6 个 view + 5 个 component，-67 行）

---

### 全局渐变精简
- [x] 替换 ultra-subtle 渐变（opacity 0.02-0.05）为 CSS 变量实色背景（InventoryView/MonitorView/RemoteOperationView/LayoutView）

### ConfigView 深度清理（历史记录）
- [x] 移除全部 hover shadow 变体（4 处 rgba box-shadow → var(--shadow-sm)）

---

## 阶段 7：全局装饰效果终极清理（已完成）

- [x] 构建配置：esbuild 双drop: ['console', 'debugger']` 双层配置（顶层+build.esbuild），生产构建零 console 输出
- [x] DashboardView: 移除 stat-card::before/::after 伪元素装饰、stat-icon hover scale、video-wrapper scanline/gradient 背景、record-icon hover scale、status-icon hover scale
- [x] PlaybackView: 移除 14 处装饰性 hover transform（translateY/scale）
- [x] LayoutView: 移除 4 处装饰性 hover transform（scale/translateX/translateY）
- [x] InventoryView: 移除 2 处装饰性 hover transform（scale）
- [x] NotFoundView: 移除 iconSpin/numberPulse/floatShape 动画、drop-shadow 发光、hover translateY
- [x] ForbiddenView: 移除 iconBounce/float/pulse/titleGlow/fadeInUp 动画、drop-shadow 发光、hover translateY
- [x] TestView: 移除 backdrop-filter blur、fadeInUp/successPulse 动画、hover scale/translateY
- [x] ThemeSwitch: 移除 2 处装饰性 hover scale
- [x] UserMenu: 移除 2 处装饰性 hover scale
- [x] Breadcrumb: 移除 1 处装饰性 hover scale
- [x] FeatureList: 移除 1 处装饰性 hover scale
- [x] HighLowPointPanel: 移除 1 处装饰性 hover scale
- [x] SystemStatus: 移除 2 处装饰性 hover translateX

## 阶段 8：注释清理与 CSS 硬编码终极清理（已完成）

### HTML 模板注释清理
- [x] DashboardView: 移除 14 条结构注释
- [x] PlaybackView: 移除 17 条结构注释
- [x] RemoteOperationView: 移除 19 条结构注释
- [x] InventoryView: 移除 19 条结构注释
- [x] ConfigView: 移除 17 条结构注释
- [x] HistoryView: 移除 15 条结构注释
- [x] LayoutView: 移除 11 条结构注释
- [x] MonitorView: 移除 7 条结构注释
- [x] FeatureSwitchView: 移除 3 条结构注释
- [x] UserManagementView: 移除 5 条结构注释
- [x] DataClearDialog: 移除 5 条结构注释
- [x] DataManager: 移除 7 条结构注释
- [x] HighLowPointPanel: 移除 4 条结构注释
- [x] PileManager: 移除 10 条结构注释
- [x] VideoPlayer: 移除 6 条结构注释
- [x] 保留 2 条有意义的注释（DiagnosticsPanel/AlgorithmConfig）

### LoginView 深度清理
- [x] 移除 15 条 HTML 模板注释
- [x] 移除 20+ 条 JSDoc 注释（script 区域）
- [x] 移除 11 条 CSS section 注释（/* === */ 格式）
- [x] 移除无用的 orb-* 响应式规则（orbs 在阶段 2 已删除）
- [x] 简化 login-card box-shadow（3 处硬编码 rgba → var(--shadow-lg)）
- [x] 简化 brand-logo box-shadow/border（硬编码 rgba → CSS 变量）
- [x] 简化 login-input box-shadow（5 处 → 简洁的 hover/focus 状态）
- [x] 简化 login-button box-shadow（4 处 → var(--shadow-md/lg/sm)）
- [x] 简化 footer-hint background/border（硬编码 rgba → CSS 变量）
- [x] 合并重复的 .footer-hint .el-icon 规则

### LayoutView CSS 注释清理
- [x] 移除 7 条 CSS section 注释

### DiagnosticsPanel 清理
- [x] 替换 linear-gradient 硬编码 rgba 为 CSS 变量

### 硬编码 rgba 统一替换为 CSS 变量
- [x] 新增 `--bg-video-overlay` CSS 变量（三套主题各定义，用于视频/点云叠加层）
- [x] InventoryView: 7 处语义色 rgba(0.1) → var(--*-light)
- [x] DashboardView: 14 处语义色 rgba(0.1/0.08/0.15) → var(--*-light) / var(--bg-tertiary)
- [x] MonitorView: 12 处语义色 + 4 处视频叠加 → CSS 变量
- [x] RemoteOperationView: 11 处语义色 + 视频叠加 → CSS 变量
- [x] PlaybackView: 2 处语义色 → CSS 变量
- [x] VideoPlayer: 3 处 rgba → var(--bg-tertiary) / var(--bg-video-overlay)
- [x] YardView: 3 处 rgba → CSS 变量
- [x] LayoutView: 6 处 box-shadow/background rgba → CSS 变量
- [x] 剩余 11 处 rgba（LoginView 登录页背景渐变、ECharts areaGradient — 无法使用 CSS 变量）

### 字体统一
- [x] 9 处 `font-family: monospace` → `var(--font-mono)`
- [x] 13 处 `'SF Mono', 'Monaco', 'Consolas', monospace` → `var(--font-mono)`
- [x] 1 处 `'IBM Plex Mono', 'SF Mono', monospace` → `var(--font-mono)`
- [x] font-family 硬编码清零（仅保留 HTML 报告模板中的 Microsoft YaHei）

### 组件提取
- [x] 提取 PlcMappingConfig 子组件（`components/config/PlcMappingConfig.vue`，~352 行，ConfigView 从 3257→2958 行）

## 阶段 9：后端稳定性与容错（已完成）

### API 层（api.js）
- [x] 添加瞬态错误自动识别（`isTransientError`：5xx / 408 / 429 / 网络断开）
- [x] 添加指数退避重试（`retryRequest`：最多 2 次重试，1s → 2s 延迟，仅对瞬态错误）
- [x] 关键只读 API 改用 `apiWithRetry`：getStatus / getInfo / getPiles / getMaterialTypes / getConfig / getConfigSchema / getScaleStatus / getMaintenanceStatus / getStatistics / getControlStatus / getRescanStatus / getVideoPtzStatus / getVideoRecordingStatus
- [x] 写操作（save/post/put/delete）保持不重试，避免重复提交

### WebSocket 层（system.js）
- [x] HTTP 轮询模式消费 `/status` 返回数据（更新 systemStatus / gantryPose / highestPoint）
- [x] HTTP 轮询期间每 10s 探测 WS 可用性，后端恢复后自动切回 WebSocket
- [x] 浏览器标签页切回时自动重连 WebSocket（`visibilitychange` 监听）
- [x] 轮询状态标记 `isPollingMode` 防止重复启动

### 视图层容错
- [x] InventoryView：`Promise.all` → `Promise.allSettled`，单个 API 失败不清空已成功加载的数据
- [x] DashboardView：`Promise.all` → `Promise.allSettled`，部分失败时保留可用数据并记录日志

---

## 阶段 10A：工业化改版收尾（待现场验证）

- [x] 全局壳层、共享布局原件、Dashboard、Monitor、Inventory、History、Config、Admin 页面完成统一改版
- [x] Playback / RemoteOperation / Login / PTZ 完成工业语言收口
- [x] 自动化校验：目标文件 `eslint` 与 `build` 通过
  已完成：2026-04-18 已补跑 `rtk npm --prefix frontend test`（164 项 `node:test`）、`rtk npm --prefix frontend run build` 和 `rtk npm --prefix frontend run test:browser -- tests/browser/monitor-browser-smoke.spec.mjs tests/browser/route-shell-browser-smoke.spec.mjs --config=playwright.config.mjs`
- [ ] 浏览器人工回归：1920x1080 首屏与主操作路径确认
- [ ] 浏览器人工回归：1366x768 下工作台工具条和右轨可用性确认
- [ ] 现场验收：远程操作页全屏、危险动作确认链路、配置页脏状态保存条
- [x] HistoryView：`refreshData` 改用 `Promise.allSettled`，区分全部成功/部分失败
- [x] HistoryView：`loadInitialData` 改用 `Promise.allSettled`，避免单个失败阻塞其他数据源

## 阶段 10B：认证与全局稳定性（已完成）

### 认证与路由
- [x] 401/403 响应拦截器（api.js）：自动登出 + 跳转登录页
- [x] 路由守卫保存返回 URL（`redirect` query param），登录后跳回原页面
- [x] Token 过期检查（user.js）：`isTokenExpired()` 检测 `userInfo.exp`，自动清理过期会话
- [x] 全局错误处理（main.js）：`app.config.errorHandler` 捕获未处理异常防止白屏

- [x] App.vue 刌用 userStore.initialize() 在 app 挂载时清除过期 token

- [x] LoginView：使用 `useRoute()` 趈费 `route.query.redirect` 跳回原始页面

- [x] `setAuthFailureHandler` 注册全局 401/403 复位回调

- [x] 登出时清理 axios 默认 headers 中的 Authorization

- [x] API 拦截器标记 `isRetryable = false` 防止重试已过期的认证请求

- [x] 路由注释清理（删除 JSDoc 鷰节注释 `/* ====== ... ====== */`），删除 7 条）

### 稡板空安全
- [x] 创建 `utils/format.js`：`safeToFixed` / `safeNumber` / `safeArray` / `safePercent` 安全格式化工具
- [x] MonitorView：`fmt()` helper 替代模板中 15 处直接 `.toFixed()` 调用
- [x] MonitorView：添加 `addLog('error')` 到 16 个 catch 块（之前仅有 console.error/warn）
- [x] InventoryView：`safeToFixed` / `safeNumber` 替代模板和 script 中 13 处 `.toFixed()` 调用
- [x] DashboardView：`formatNumber` / `formatTrend` 添加 `Number.isFinite` 安全检查
- [x] DashboardView：`pile.volume.toFixed(1)` → `Number(pile.volume || 0).toFixed(1)`
- [x] ConfigView：`currentWeight.toFixed(2)` → `Number(currentWeight || 0).toFixed(2)` (3 处)
- [x] ConfigView：`transformationResult.error.toFixed(4)` → 安全包裹
- [x] ConfigView：`transformationResult.translation.map(v => v.toFixed(4))` → 安全包裹
- [x] ConfigView：特征点坐标 `point.x.toFixed(2)` → `Number(point.x || 0).toFixed(2)`
- [x] 路由守卫注释清理（删除 JSDoc 风格注释）

## 阶段 11：全局空安全与数据服务加固（已完成）

### PlaybackView 稳定性
- [x] `Promise.all` → `Promise.allSettled`（2 处：日期范围切换 + 初始化加载）
- [x] `.toFixed()` 安全包裹（4 处）：currentOperation.volume / map.totalVolume / volumeChange / averageOperationVolume

### InventoryView 剩余空安全
- [x] `comparisonResult.volumeChange.toFixed(2)` → `safeToFixed` (5 处：体积/重量/料堆数量变化值和百分比)
- [x] `selectedRecord.volume.toFixed(2)` → `safeToFixed` (3 处：体积/密度/重量详情)
- [x] 导出函数中的 `.toFixed()` 保持原样（CSV/HTML 导出时数据由 `buildInventoryRows` 生成，字段已确保是数字）

### DashboardView 剩余空安全
- [x] `gantryPose.x.toFixed(2)` → `Number(gantryPose.x || 0).toFixed(2)` (2 处)
- [x] `highestPoint.relative.z.toFixed(2)` → 安全包裹

### HistoryView
- [x] `formatVolume()` 函数添加 `Number.isFinite` 检查

### data.service.js 加固
- [x] 所有 `response.data` 添加 `Array.isArray` 检查（5 个函数）
- [x] 所有 `parseFloat()` 添加 `|| 0` fallback（15+ 处）
- [x] 所有 `JSON.parse()` 添加 try/catch fallback（3 处：grabPositions / pilesDetail / coordinates / config_value）

### 组件提取
- [x] 提取 ScaleConfig 子组件（`components/config/ScaleConfig.vue`，~1035 行，ConfigView 从 2958→2106 行）
- [x] ScaleConfig 自管理称重状态轮询（5s interval，onUnmounted 自动清理）
- [x] ScaleConfig 拥有 `loadConfigData(configMap, scaleStatusResponse)` 接口
- [x] ConfigView 清理 23 个死代码函数/refs、所有 `.scale-*` CSS

### 其他修复
- [x] MonitorView：边界文件 JSON 解析添加 try/catch（防 `.json` 文件内容损坏崩溃）
- [x] InventoryView：导出报告 CSV/HTML 中 15 处 `.toFixed()` → `safeToFixed`（数据由 buildInventoryRows 生成，额外防护）

## 阶段 12：组件层空安全（已完成）

### 组件空安全修复
- [x] YardView：`highestPoint.relative.z.toFixed(1)` → `Number(highestPoint.relative?.z || 0).toFixed(1)`
- [x] YardView：`gantryPose.x.toFixed(1)` 等 6 处 → `Number(gantryPose.x || 0).toFixed()`
- [x] YardView：Canvas 绘制函数中 `props.gantryPose.x.toFixed(1)` → 安全包裹
- [x] PileManager：`totalVolume.toFixed(2)` / `totalWeight.toFixed(2)` → `Number(x || 0).toFixed(2)`
- [x] PileManager：`scope.row.currentVolume.toFixed(2)` → `Number(scope.row.currentVolume || 0).toFixed(2)`
- [x] PileManager：`calculateROIVolume` 返回值安全包裹
- [x] RemoteOperationView：`highestPoint.toFixed(2)` / `lowestPoint.toFixed(2)` → `Number(x || 0).toFixed(2)`
- [x] MonitorView：`buildRoiFromPoints` 添加 `Array.isArray` 前置检查
- [x] MonitorView：高级搜索 ROI 描述使用已标准化的 `roi` 变量避免 null 访问

### 用户反馈补全
- [x] DashboardView：部分请求失败 `console.warn` → `ElMessage.warning`（区分全部失败/部分失败）
- [x] HistoryView：初始化部分失败 `console.warn` → `ElMessage.warning`（区分全部失败/部分失败）

## 阶段 13：Store/全局稳定性加固（已完成）

### Store 层加固
- [x] user.js：`JSON.parse(localStorage.getItem('userInfo'))` 添加 try/catch，防止损坏 JSON 导致白屏
- [x] system.js：`stopHttpPolling` 补充清理 `wsReconnectTimer`，防止清理后定时器仍触发重连
- [x] system.js：`handleMessage` 添加 `message`/`message.type` 空检查 + `message.data ?? {}` 安全默认值

### 资源泄漏修复
- [x] InventoryView：`window.addEventListener('resize', ...)` 提取为命名函数，`onUnmounted` 中 `removeEventListener`

## 阶段 14：最终稳定性验证（已完成）

### 空安全全面清查
- [x] 全项目 `.toFixed()` 安全审查：所有模板中的 `.toFixed()` 均已用 `Number(x || 0).toFixed()` 或 `?.toFixed()` 包裹
- [x] 脚本中的 `.toFixed()` 均在已有类型检查的格式化函数内（DiagnosticsPanel/RescanActions/MonitorView/DashboardView/HistoryView）
- [x] ConfigView `formatMatrix` 添加 `Array.isArray` 防护
- [x] 所有 ECharts 实例在 `onUnmounted` 中正确 `dispose()`（InventoryView 5 个/HistoryView 2 个/DashboardView 3 个/PlaybackView renderer）
- [x] 无 `console.log` 生产泄漏（全项目仅使用 `console.error` / `console.warn`）

## 阶段 15：前后端 API 对齐审计（已完成）

### API 路由映射
- [x] 完成后端 80+ 条路由 vs 前端 api.js 50+ 条调用的精确对比
- [x] 确认路径前缀一致：前端 BASE_URL = `/api`，Vite proxy → `:8080`，后端注册 `/api/xxx`
- [x] 识别 4 条前端死代码路由（`/material-operations`、`/boundaries`、`/logs`、`/statistics`）— 未被任何视图调用，不影响运行时

### api.js 路由补齐
- [x] 新增 `authLogout` / `authRefresh` / `authMe` — 对接后端 `/api/auth/*`
- [x] 新增 `getUsers` / `createUser` / `updateUser` / `deleteUser` / `resetUserPassword` — 用户管理完整 CRUD
- [x] 新增 `getFeatures` / `updateFeature` — 功能开关读写
- [x] 新增 `getOperationMode` / `startOperation` / `stopOperation` / `getOperationPoints` — 运行模式管理
- [x] 新增 `getHistoryStatistics` / `getHistoryExport` — 历史统计与导出
- [x] 新增 `getInventorySnapshot` — 单条快照查询
- [x] 新增 `getPointcloudDownload` / `getVideoFileDownload` / `getVideoFileStream` — 文件下载辅助

## 阶段 16：统一 API 调用通道（已完成）

### featureSwitches.js 修复
- [x] 移除原始 `fetch()` 调用，改用 `api.getFeatures()` / `api.updateFeature()`
- [x] 统一受 api.js 拦截器保护（auth/401/403/重试）

### UserManagementView 修复
- [x] 移除原始 `axios` + 手动 `Authorization` header 模式
- [x] 改用 `api.getUsers()` / `api.createUser()` / `api.updateUser()` / `api.deleteUser()` / `api.resetUserPassword()`
- [x] 自动继承 api.js 的认证拦截器（无需手动传 header）

### HistoryView 修复
- [x] 移除 4 处原始 `axios.get` 调用（today/operations×2/export）
- [x] 改用 `api.get()` / `getHistoryOperations()` — 统一认证和重试

### user.js logout 修复
- [x] `logout()` 改为 `async`，先调后端 `/auth/logout` 再清理本地状态
- [x] 后端登出失败不阻塞前端清理（`try/catch` 静默忽略）

## 阶段 17：统一 API 调用通道与死代码清理（已完成）

### RemoteOperationView API 统一
- [x] 移除 `BACKEND_API_BASE_URL` + raw `fetch()` 调用（2 处：`fetchPlcStatus`、`sendControlCommand`）
- [x] 改用 `api.js` 的 `getControlStatus` / `sendMoveCommand` / `sendGotoCommand` / `sendStopCommand` 等
- [x] 所有控制指令自动继承认证拦截器和错误处理
- [x] 修复 `clearFault` 命名冲突（本地函数重命名 `handleClearFault`）

### 死代码清理
- [x] 删除 `TestView.vue`（无路由指向，纯开发调试页面）

### 后端能力对齐状态
- Operations mode (`/operations/*`) — 后端已实现，前端 api.js 已补齐函数，待视图层按需接入
- History statistics (`/history/statistics`) — 后端已实现，前端 api.js 已补齐函数，待 HistoryView 按需接入
- Feature toggle — 后端 `PUT /features/:type {enabled}` 已对接 featureSwitches.js

## 阶段 18：视频流与认证统一（已完成）

### 视频流 URL 改进
- [x] MonitorView: `getDefaultVideoUrl()` 移除 `typeof window === 'undefined'` 时返回硬编码 localhost 的 fallback
- [x] 优先使用 `VITE_HLS_URL` 环境变量，无环境变量时才 fallback 到动态构建

### system.js HTTP 轮询认证
- [x] `startHttpPolling` 中 `fetch('/status')` 添加 `Authorization` header，与 api.js 保持一致

## 阶段 19：Loading 状态与操作反馈审计（已完成）

### ScaleConfig 保存 Loading
- [x] 新增 `scaleSaving` ref + 防双击 guard（`if (scaleSaving.value) return`）
- [x] 保存按钮添加 `:loading="scaleSaving"`
- [x] `finally` 块确保 loading 状态重置

### 全局 Loading 状态审计结果
- InventoryView `measureInventory` — ✅ loading + error feedback
- RescanActions — ✅ loading（props 驱动）
- ConfigView `saveRuntimeConfig` — ✅ loading + error feedback
- LoginView — ✅ loading + 双击防护（button disabled）
- MonitorView 录像控制 — ✅ loading + 双击防护

## 阶段 20：Token 静默刷新（已完成）

### user.js 改造
- [x] 新增 `refreshToken` ref — 存储 refresh_token，持久化到 localStorage
- [x] 新增 `setSession()` 统一管理登录/刷新后的 token+refreshToken+userInfo 存储
- [x] `login()` 改用 `setSession()` 存储 refresh_token
- [x] `logout()` 清理 refreshToken
- [x] 新增 `tryRefreshToken()` — 调后端 `POST /auth/refresh { refresh_token }`，成功更新 token
- [x] 新增 `handleTokenExpired()` — 防并发刷新：第一个请求刷新，其他请求排队等待
- [x] `initialize()` 检测 token 过期时优先尝试 refresh，失败才登出

### api.js 拦截器改造
- [x] 401 响应拦截器：先尝试 `handleTokenRefresh()`，成功后自动重发原请求
- [x] 新增 `setTokenRefreshHandler()` — 懒注册模式（避免循环导入）
- [x] 并发请求去重：第一个 401 触发 refresh，后续 401 请求排队等待新 token
- [x] refresh 失败才触发 authFailureHandler（登出+跳转登录页）

### App.vue
- [x] 注册 `setTokenRefreshHandler(() => userStore.handleTokenExpired())`

### 关键 Bug 修复
- [x] **httpClient 请求拦截器**：`axios.create()` 不继承 `axios.defaults`，导致 api.js 所有请求无 Authorization header。新增请求拦截器从 localStorage 读取 token 自动注入

### 2026-04-03 前端优化引发的后端需求
- **[已完成]** `/api/monitor/trajectory` — 后端已提供历史轨迹点列表，PlaybackView 已接入真实轨迹查询链路
- **[改进]** WebSocket `ws/monitor` 消息中的轨迹窗口诊断字段已消费（`trajectoryWindowActive/Frames/Distance`）
  - 后端侧已实现，前端已接入展示，无需额外改动

---

## 后端待办事项（需要后端配合的前端改进）

以下事项需要后端 API 支持或现场硬件验证，记录在此便于跨会话跟踪：

### 需要后端 API 支持
- [x] ~~Three.js 点云轨迹数据~~ — MonitorView 已改为消费实时龙门吊位姿数据（`trajectoryPoints`）
- [x] ~~ECharts 图表主题切换响应~~ — 前端已通过 MutationObserver 监听 `data-theme` 变化自动重新 `setOption`
- [x] PlaybackView 历史轨迹数据（已接入 `/api/monitor/trajectory`）
- [ ] 智能标注层动态位置（需后端在 WebSocket 中推送目标跟踪像素坐标 `{px, py}` 或世界坐标 `{wx, wy, wz}`）
- [x] `/api/history/operations` 分页参数对齐 — 后端已支持 `page/pageSize/sortBy/sortOrder/startTime/endTime/operationType/operationSource/pileId`
- [x] `/api/history/today` 返回字段确认 — 后端已返回 `totalOperations/decreaseCount/increaseCount/totalVolume*`
- [x] `/api/history/export` CSV 导出 — 后端现已支持 `operationType/operationSource/pileId/startTime/endTime` 筛选参数
- [x] `/api/config/schema` 运行参数 Schema — 后端已返回 `key/label/type/group/defaultValue/value/restartRequired/applyMode`
- [x] `/api/scales/status` 称重设备实时状态 — 后端已返回 `driverAvailable/driverStatus/devices[].hardwareConnected/currentWeight/sampleTime`
- [x] `/api/system/maintenance/status` — 后端已返回 `mysqldumpAvailable/systemctlAvailable/scaleDriverAvailable`
- [x] `/api/material-types` CRUD 接口 — 后端已支持 GET/POST/PUT/DELETE 按类型编码操作
- [x] `/api/piles` 料堆 ROI 数据 — 后端已返回 `roi: {minX, maxX, minY, maxY, minZ, maxZ}` 结构
- [x] WebSocket `ws/monitor` 消息格式 — 后端已稳定发送 `gantryPose/highestPoint/processingDiagnostics/globalMap`

### 需要现场硬件验证
- [ ] ARM Debian 11 目标机完整构建与联调验收
- [ ] 真实摄像头 ONVIF PTZ 联调（前端 PtzControls 已就绪，需后端 ONVIF 协议适配）
- [ ] 真实视频源截图与录像兼容性验证（HLS/RTSP 转 m3u8）
- [ ] 真实料堆慢速扫描盲区补偿参数验证（RescanActions 已就绪，需后端算法参数调优）
- [ ] 真实串口/网口称重设备接入（ScaleDevice 配置面板已就绪，需后端 Modbus/连续输出驱动联调）
- [ ] 坐标校准流程端到端验证（配置中心 `/config/business/calibration` 已就绪，需真实点云数据验证变换矩阵）
- [ ] 所有配置中心、接口对齐与联调项完成后，完整部署到测试机做最终回归，逐项清零现场问题并回写文档/清单
  本轮进展：2026-04-15 已完成配置中心与接口对齐版本的测试机部署和 API/静态资源验活，详见 `docs/frontend-backend-interface-alignment.md`

### 前端已就绪、等后端联调的功能清单
| 功能 | 前端组件 | 后端依赖 |
|------|---------|---------|
| 实时监控(视频+点云+货场) | MonitorView | WebSocket + HLS 流 + 点云数据 |
| 历史回放(点云快照+轨迹) | PlaybackView | `/api/monitor/trajectory` + 快照 API |
| 批量盘点 | MonitorView 对话框 | `/api/inventory/measure` |
| 补扫分析与执行 | RescanActions | WebSocket rescanStatus + executeRescan |
| PLC 寄存器映射管理 | ConfigPlcView | `/api/config` (ui/plc_mappings) |
| 称重设备管理+实时监控 | ConfigScaleDeviceView | `/api/scales/*` |
| 盘存周期管理 | ConfigScheduleStrategyView | `/api/config` (ui/inventory_schedules) |
| 坐标校准(5步向导) | ConfigCalibrationView | 点云采集 + 变换矩阵保存 |
| 物料类型 CRUD | ConfigMaterialsView | `/api/material-types` |
| 系统维护(备份/缓存/重启) | ConfigMaintenanceView | `/api/system/maintenance/*` |
| 远程操控(龙门吊控制) | RemoteOperationView | `/api/control/*` (requestControl/move/goto/stop) |
| 运行参数管理 | ConfigRuntimeView | `/api/config/schema` + `saveConfigEntries` |
| 算法预设应用 | ConfigAlgorithmPresetView | `saveConfigEntries` 写入 processing/* 参数 |

> 详见根目录 `todo.md` 的完整后端待办清单。
