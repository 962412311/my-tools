# 前端架构文档

> 最后更新：2026-04-16
> 目的：新会话快速上手，理解项目结构、设计系统、组件关系、已知问题

---

## 1. 技术栈

### 1.1 推荐阅读与验证入口

- 先看仓库总览：[README.md](../README.md)
- 快速建立仓库上下文先看：[GOGS RTK（快速上手包）](../../docs/gogs-rtk.md)
- 当前前端整体验证优先使用：`rtk npm --prefix frontend run build` 和 `rtk npm --prefix frontend test`
- 浏览器 smoke 入口：`rtk npm --prefix frontend run test:browser -- tests/browser/monitor-browser-smoke.spec.mjs --config=playwright.config.mjs`
- 首次执行浏览器 smoke 前先运行：`rtk npm --prefix frontend run test:browser:install`
- 如果只跑单个 `node --test` 文件，建议显式从 `frontend/` 目录执行：`rtk bash -lc 'cd frontend && node --test tests/xxx.test.mjs'`

| 层面 | 技术 | 版本 |
|------|------|------|
| 框架 | Vue 3 (Composition API + `<script setup>`) | 3.3.4 |
| 构建 | Vite | 5.4.14 |
| UI 库 | Element Plus | 2.3.14 |
| 状态管理 | Pinia | 2.1.6 |
| 路由 | Vue Router 4 | 4.2.4 |
| 3D 渲染 | Three.js (点云/轨迹) | 0.155.0 |
| 图表 | ECharts 5 (Canvas 模式) | 5.4.3 |
| 字体 | HarmonyOS Sans SC / PingFang SC / JetBrains Mono（系统优先，无外网依赖） | — |
| HTTP | Axios | 1.5.0 |
| 实时通信 | WebSocket + HTTP Polling 降级 | — |
| 视频 | Video.js | 8.5.2 |
| 日期 | Day.js | 1.11.9 |

## 2. 目录结构

```
frontend/src/
├── App.vue                    # 根组件（挂载 userStore.initialize + tokenRefresh 注册）
├── main.js                    # 入口：挂载 Pinia/Router/ElementPlus，全局错误处理
├── router/index.js            # 路由配置 + 权限守卫（admin/super_admin/requiredPermission）
├── stores/                    # Pinia 状态管理
│   ├── system.js              # 系统状态、WebSocket 连接、实时数据（位姿/点云/诊断）
│   ├── user.js                # 用户认证、角色、Token 刷新
│   ├── featureSwitches.js     # 功能开关（支持本地/服务端模式）
│   └── theme.js               # 主题状态管理
├── services/
│   ├── api.js                 # Axios 实例 + 全部后端 API 封装（50+ 函数）+ 认证拦截器
│   └── data.service.js        # 数据转换辅助（CSV/HTML 导出格式化）
├── views/                     # 页面组件（路由级）
│   ├── LayoutView.vue         # 主布局：侧边栏 + 顶栏 + 内容区
│   ├── LoginView.vue          # 登录页
│   ├── DashboardView.vue      # 仪表盘/总览
│   ├── MonitorView.vue        # 实时监控（最大组件，含 Three.js 点云渲染）
│   ├── InventoryView.vue      # 盘存管理
│   ├── config/               # 新配置中心（按作业运维/设备通信/业务配置/高级维护拆分）
│   ├── HistoryView.vue        # 历史记录
│   ├── PlaybackView.vue       # 历史回放（视频+点云+作业三轨道联动）
│   ├── RemoteOperationView.vue # 远程操控（PLC 手柄控制+任务管理）
│   ├── FeatureSwitchView.vue  # 功能开关管理
│   ├── UserManagementView.vue # 用户管理（配置中心高级维护域页面）
│   ├── NotFoundView.vue       # 404
│   └── ForbiddenView.vue      # 403
├── components/                # 通用组件
│   ├── monitor/               # MonitorView 子组件
│   │   ├── DiagnosticsPanel.vue   # 处理诊断面板（按功能分组：基础/标定/补扫/盲区/轨迹）
│   │   ├── RescanActions.vue      # 补扫执行操作（分析/执行/取消）
│   │   ├── PtzControls.vue        # 云台控制（方向/变焦/预置位）
│   │   └── YardView.vue           # 货场全局俯视图（Canvas 2D，自带 100ms 定时刷新）
│   ├── config/                # 配置中心复用组件与工作台骨架
│   │   ├── AlgorithmConfig.vue        # 算法配置（调参预设/参数说明/测试运行）
│   │   ├── DataManageConfig.vue       # 物料类型管理
│   │   ├── InventoryScheduleConfig.vue # 盘存周期管理
│   │   ├── PlcMappingConfig.vue       # PLC 寄存器映射配置
│   │   └── ScaleConfig.vue            # 称重设备配置（Modbus 参数+实时状态）
│   ├── config-center/         # 配置中心共享壳层/入口/状态组件
│   ├── VideoPlayer.vue        # 视频播放器（video.js）
│   ├── Breadcrumb.vue         # 面包屑导航
│   ├── ConnectionStatus.vue   # 连接状态指示
│   ├── SystemStatus.vue       # 系统状态面板
│   ├── ThemeSwitch.vue        # 主题切换（light/dark/industrial 三套）
│   ├── UserMenu.vue           # 用户菜单
│   ├── FeatureList.vue        # 功能列表
│   ├── PileManager.vue        # 料堆管理
│   ├── DataManager.vue        # 历史遗留数据管理组件（不属于当前主线路由）
│   ├── DataClearDialog.vue    # 数据清除对话框
│   └── HighLowPointPanel.vue  # 高低点面板
├── styles/
│   └── theme.css              # 全局设计令牌（CSS 自定义属性，三套主题）
├── utils/
│   ├── echarts.js             # ECharts 按需导入
│   ├── theme.js               # getThemePalette() / getCssVar() — 运行时读取 CSS 变量供 Canvas/ECharts 使用
│   ├── format.js              # safeToFixed / safeNumber / safeArray / safePercent 安全格式化
│   └── rescan.js              # 补扫分析字段统一消费
├── config/
│   ├── index.js               # 应用配置（BASE_URL / WS_URL / 数据源模式）
│   └── permission.js          # 权限定义
├── composables/
│   ├── index.js
│   ├── usePermission.js       # 权限组合式函数
│   └── useTable.js            # 表格通用逻辑
└── directives/
    ├── usePermission.js       # 权限指令
    └── useTable.js            # 表格指令
```

## 3. 设计系统（theme.css）

### 3.1 主题机制
- 基于 CSS 自定义属性（`--var-name`）
- 三套主题：浅色（light）、深色（dark）、工业蓝（industrial）
- 切换通过 `<html data-theme="xxx">` 属性
- **所有颜色必须使用 CSS 变量**，禁止硬编码 rgba 值
- Canvas/ECharts 中无法使用 `var()`，必须通过 `getThemePalette()` 读取 CSS 变量值

### 3.2 核心变量

| 类别 | 变量前缀 | 示例 |
|------|----------|------|
| 背景色 | `--bg-*` | `--bg-card`, `--bg-elevated`, `--bg-hover`, `--bg-pressed` |
| 文字色 | `--text-*` | `--text-primary`, `--text-secondary`, `--text-tertiary`, `--text-white` |
| 边框色 | `--border-*` | `--border-color`, `--border-light`, `--border-glass` |
| 语义色 | `--primary-*`, `--success-*`, `--warning-*`, `--danger-*`, `--info-*` | `--primary-color`, `--success-gradient` |
| RGB 值 | `--*-rgb` | `--primary-color-rgb: 29, 78, 216`（用于 Canvas rgba 构造） |
| 阴影 | `--shadow-*` | `--shadow-sm`, `--shadow-md`, `--shadow-lg` |
| 间距 | `--space-*` | `--space-xs` ~ `--space-4xl` |
| 圆角 | `--radius-*` | `--radius-sm`, `--radius-md`, `--radius-lg`, `--radius-xl` |
| 字体 | `--font-*` | `--font-ui`, `--font-display`, `--font-sans`, `--font-mono` |
| 过渡 | `--transition-*` | `--transition-base`, `--transition-fast`, `--transition-spring` |

### 3.4 视觉基线与维护约定

- 中文正文一律使用 `--font-ui`，避免在页面里单独写 `font-family`
- 标题、章节名、导航分组标签优先使用 `--font-display`，但必须保留中文回退
- 交互基础件统一高度令牌：
  - `--control-height-sm: 32px`
  - `--control-height-md: 38px`
  - `--control-height-lg: 44px`
  - `--control-height-xl: 48px`
- 顶栏状态件统一使用 `ui-chip` 协议，`ConnectionStatus / SystemStatus / ThemeSwitch / UserMenu` 不再各自维护一套壳子样式
- 需要居中的中文控件文字，不要在页面局部反复修补；统一走 `src/style.css` 中的 Element Plus 基础件规则
- `el-radio-button`、`el-button-group` 这类“标签式切换/操作组”必须复用公共尺寸档位与 `line-height: 1.1` 契约，页面局部样式只允许改外观，不允许单独改回高度、padding 或行高
- 新页面优先复用 `LayoutView + PageHeader + WorkbenchToolbar + SectionCard`，不要另起一套壳层视觉

### 3.3 Canvas/ECharts 颜色方案

Canvas 和 ECharts 无法解析 CSS `var()`，使用 `utils/theme.js` 的 `getThemePalette()`：

```js
import { getThemePalette } from '@/utils/theme.js'

// 在绘制函数内调用（确保主题切换后重新读取）
const colors = getThemePalette()
ctx.fillStyle = colors.bgElevated
ctx.fillStyle = `rgba(${colors.dangerRgb}, 0.9)`
```

返回的 palette 包含：`primary/primaryRgb/warning/warningRgb/danger/dangerRgb/info/infoRgb/success/successRgb/bgCard/bgElevated/borderLight/textPrimary/textPrimaryRgb` 等。

**关键**：必须在每次绘制时调用 `getThemePalette()` 而非缓存，否则主题切换不生效。

## 4. 路由与权限

路由在 `router/index.js` 中配置：
- 公开路由：`/login`
- 需登录路由：`/dashboard`、`/monitor`、`/inventory`、`/history`、`/playback`、`/remote`
- 管理员路由：`/config`（meta.admin: true）
- 超管路由：`/features`（meta.superAdmin: true）
- 路由守卫检查 `userStore.isLoggedIn` 和 `userStore.role`
- 登录后跳回原页面（`redirect` query param）

## 5. 实时数据流

```
后端 WebSocket (ws://host:12345) ──→ stores/system.js ──→ 各 View 组件
                    │
                    ├─ type: 'status'              → systemStatus
                    ├─ type: 'pointCloud'          → pointCloud (Three.js)
                    ├─ type: 'globalMap'            → globalMap
                    ├─ type: 'gantryPose'           → gantryPose (x/y/z/theta)
                    ├─ type: 'highestPoint'         → highestPoint
                    ├─ type: 'volumeRecords'        → volumeRecords
                    └─ type: 'processingDiagnostics'→ processingDiagnostics (30+ 字段)
                    
HTTP Polling (降级) ──→ 每 5s GET /api/status ──→ 相同数据路径
                     └─ 每 10s 探测 WS 可用性，恢复后自动切回
```

## 6. 组件拆分现状

### Shared layout primitives

| 组件 | 路径 | 职责 |
|------|------|------|
| PageHeader | `components/layout/PageHeader.vue` | 统一页面标题、摘要、主操作和头部状态信息 |
| StatusCluster | `components/layout/StatusCluster.vue` | 紧凑状态分组容器，用于壳层和页面头部 |
| SectionCard | `components/layout/SectionCard.vue` | 统一工业面板卡片，支持标题、动作区和密度模式 |
| WorkbenchToolbar | `components/layout/WorkbenchToolbar.vue` | 统一筛选、摘要、操作条，服务工作台类页面 |

### 页面布局分层

- `DashboardView`、`MonitorView`、`PlaybackView`、`RemoteOperationView` 采用 `command-center` 风格：
  `PageHeader + 状态摘要/工具条 + 主任务区 + 右轨辅助区`
- `InventoryView`、`HistoryView`、`views/config/*`、`UserManagementView`、`FeatureSwitchView` 采用 `workbench` 风格：
  `PageHeader + WorkbenchToolbar + SectionCard/抽屉/表格详情`
- `LoginView` 保持独立入口页，但视觉语言和状态提示与工业主题一致
- 所有页面共用相同的设计令牌、状态色和危险操作分层规则

### MonitorView 子组件

| 子组件 | 路径 | 职责 |
|--------|------|------|
| DiagnosticsPanel | `components/monitor/DiagnosticsPanel.vue` | 处理诊断面板（按功能分组：基础/标定/补扫/盲区/轨迹） |
| RescanActions | `components/monitor/RescanActions.vue` | 补扫分析/执行/取消按钮 |
| PtzControls | `components/monitor/PtzControls.vue` | 云台方向控制/变焦/预置位 |
| YardView | `components/monitor/YardView.vue` | 货场全局俯视图（Canvas 2D，料堆 ROI/行车/最高点/轨迹） |

### 配置中心复用组件

| 子组件 | 路径 | 职责 |
|--------|------|------|
| AlgorithmConfig | `components/config/AlgorithmConfig.vue` | 算法调参预设/参数说明/测试运行 |
| DataManageConfig | `components/config/DataManageConfig.vue` | 物料类型 CRUD 管理 |
| InventoryScheduleConfig | `components/config/InventoryScheduleConfig.vue` | 盘存周期配置 |
| PlcMappingConfig | `components/config/PlcMappingConfig.vue` | PLC 寄存器映射配置 |
| ScaleConfig | `components/config/ScaleConfig.vue` | 称重设备配置与实时监控 |
| UserManagementView | `views/UserManagementView.vue` | 用户管理（独立挂在配置中心高级维护域） |

**暂缓提取**：VideoPanel（过多 props/handlers，成本收益不成比例）

## 7. 性能约束

目标设备：工业平板（1366x768 ~ 1920x1080）

已实施的性能优化：
- **ECharts 按需导入** — 只导入使用的 chart 类型（见 utils/echarts.js）
- **系统字体优先** — 移除外网字体依赖，适配内网/离线工业部署
- **Vite code splitting** — vendor-vue / vendor-element / vendor-chart / vendor-3d 独立 chunk
- **esbuild drop console** — 生产构建零 console 输出
- **移除装饰性动画** — scanline/pulse/float/glow/keyframe 动画已全部移除
- **移除 backdrop-filter: blur()** — GPU 开销大，已替换为实色半透明背景
- **移除 hover transform** — translateY/scale/rotate 改为简单背景变化

## 8. 后端 API 概览

后端为 Qt 6.2.4 C++ HTTP 服务，默认端口 8080。

| API 路径前缀 | 方法 | 用途 | 前端服务函数 |
|-------------|------|------|-------------|
| `/api/auth/*` | POST | 认证（login/logout/refresh/me） | authLogout/authRefresh/authMe |
| `/api/users*` | CRUD | 用户管理 | getUsers/createUser/updateUser/deleteUser/resetUserPassword |
| `/api/piles*` | CRUD | 料堆管理 | getPiles/createPile/updatePile/deletePileById/updatePileRoi |
| `/api/material-types*` | CRUD | 物料类型 | getMaterialTypes/createMaterialType/updateMaterialType/deleteMaterialTypeByCode |
| `/api/inventory-snapshots*` | GET/POST | 库存快照 | getInventorySnapshots/compareInventorySnapshots/measureInventory |
| `/api/history/*` | GET | 历史数据 | getHistoryOperations/getHistoryStatistics/getHistoryExport |
| `/api/config` | GET/POST | 运行时配置 | getConfig/getConfigSchema/saveConfig/saveConfigEntries |
| `/api/control/*` | POST | 远程控制 | requestControl/releaseControl/sendMoveCommand/sendGotoCommand/sendStopCommand 等 |
| `/api/video/*` | GET/POST | 视频控制 | moveVideoPtz/stopVideoPtz/getVideoRecordingStatus/startVideoRecording 等 |
| `/api/scales/*` | GET/POST | 称重设备 | getScaleStatus/saveScaleDevices/submitScaleReadings |
| `/api/rescan/*` | GET/POST | 补扫 | getRescanStatus/analyzeRescanStatus/executeRescan/cancelRescan |
| `/api/features*` | GET/PUT | 功能开关 | getFeatures/updateFeature |
| `/api/operations/*` | GET/POST | 运行模式 | getOperationMode/startOperation/stopOperation/getOperationPoints |
| `/api/system/*` | GET/POST | 系统维护 | getSystemMaintenanceStatus/backupSystem/clearSystemCache/restartSystem |

后端默认端口：
- HTTP API：`http://127.0.0.1:8080/api`
- WebSocket：`ws://127.0.0.1:12345`

## 9. 构建与部署

```bash
# 开发（通过脚本）
rtk ./scripts/frontend-dev.sh

# 开发（手动）
rtk bash -lc 'cd frontend && npm run dev'

# 构建
rtk ./scripts/frontend-build.sh

# 当前推荐整体验证
rtk npm --prefix frontend run build
rtk npm --prefix frontend test

# 生产环境配置
cp frontend/.env.production.example frontend/.env.production
# 编辑 VITE_API_BASE_URL 和 VITE_WS_URL 指向实际后端
```

如果是测试机前端发布，当前推荐直接使用：

```bash
rtk bash scripts/arm/deploy_frontend.sh
```

默认管理员：`admin / Admin@123`

## 10. 待处理事项

详见 `frontend/docs/todo.md`。

关键待办：
- 智能标注层动态位置（需后端提供目标跟踪坐标）
- 1920x1080 / 1366x768 浏览器人工回归验收
- ARM Debian 11 目标机完整构建与联调验收
- 统一自检入口仍需从视频链路扩展到 `PLC / 称重 / 数据库 / 磁盘 / 进程`
- 多个后端 API 返回字段待现场确认（见 todo.md 后端待办事项章节）
