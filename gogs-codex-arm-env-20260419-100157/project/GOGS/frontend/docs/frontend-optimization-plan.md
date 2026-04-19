# 前端全面优化计划

> 历史计划说明：本文档是 2026-04-03 的阶段性优化计划，绝大多数事项已被后续实现、`frontend/docs/todo.md` 和现行架构文档吸收，不再作为当前任务分发表。
> 当前请优先参考：`frontend/docs/todo.md`、`frontend/docs/frontend-architecture.md`、`docs/gogs-rtk.md`。

> 项目：抓斗作业引导及盘存系统 (Grab Guidance & Inventory System)
> 日期：2026-04-03
> 状态：历史计划（已归档）

---

## 一、已识别问题清单

### P0 - 必须修复（影响可维护性与正确性）

| # | 问题 | 文件 | 说明 |
|---|------|------|------|
| 1 | CSS 大段重复定义 | LoginView.vue, DashboardView.vue, MonitorView.vue | 同一选择器在 `<style>` 块内定义两次，后者覆盖前者，造成维护混乱和体积膨胀 |
| 2 | MonitorView.vue 过于庞大（5688 行） | MonitorView.vue | 单文件混合了 4 种布局、PTZ 控制、Three.js 渲染、货场视图、搜索、录像、补扫等所有逻辑 |
| 3 | theme.css 在 scoped 样式中重复 @import | 所有 View 组件 | scoped `@import '../styles/theme.css'` 在每个组件内重复引入，构建后体积膨胀 |

### P1 - 应当修复（影响性能与专业度）

| # | 问题 | 文件 | 说明 |
|---|------|------|------|
| 4 | 字体选用过于通用 | theme.css | `--font-sans: 'Inter', ...` 是典型 AI 生成体，缺乏工业系统辨识度 |
| 5 | 装饰性 CSS 动效过多 | MonitorView.vue, DashboardView.vue, LoginView.vue | pulse、glow、float、scanline、fadeInUp 等动画在工业平板上消耗 GPU 资源 |
| 6 | 工具栏/诊断区信息密度过低 | MonitorView.vue | 工具栏按钮+标签行数过多，诊断区 30+ 网格项可分组压缩 |
| 7 | console.log 残留 | system.js, MonitorView.vue | 生产代码中有多处 console.log/console.error |
| 8 | ECharts tooltip 样式使用 CSS 变量字符串 | DashboardView.vue 等 | `var(--text-primary)` 在 ECharts 配置中无法被解析 |

### P2 - 建议优化（提升体验与品牌感）

| # | 问题 | 文件 | 说明 |
|---|------|------|------|
| 9 | 色彩体系偏"模板化" | theme.css | 深空蓝+渐变光效是典型 dashboard 模板风格，缺乏工业装备系统的硬朗感 |
| 10 | 加载动画过于通用 | index.html | 旋转圆环+网格背景，缺乏项目特色 |
| 11 | 登录页装饰球/渐变与工业定位不符 | LoginView.vue | 装饰性浮动光球和渐变背景偏消费级产品风格 |

---

## 二、执行步骤

### 阶段 1：基础清理（P0）

- [ ] 1.1 清理 LoginView.vue CSS 重复
- [ ] 1.2 清理 DashboardView.vue CSS 重复
- [ ] 1.3 清理 MonitorView.vue CSS 重复
- [ ] 1.4 移除所有 scoped `@import theme.css`

### 阶段 2：组件拆分（P0）

- [ ] 2.1 MonitorView.vue 拆分：提取 VideoPanel 组件
- [ ] 2.2 MonitorView.vue 拆分：提取 PointCloudPanel 组件
- [ ] 2.3 MonitorView.vue 拆分：提取 YardView 组件
- [ ] 2.4 MonitorView.vue 拆分：提取 DiagnosticsPanel 组件
- [ ] 2.5 MonitorView.vue 拆分：提取 SearchPanel 组件
- [ ] 2.6 MonitorView.vue 拆分：提取 RecordingControls 组件
- [ ] 2.7 MonitorView.vue 拆分：提取 RescanPanel 组件
- [ ] 2.8 MonitorView.vue 拆分：提取 PtzControls 组件

### 阶段 3：性能与专业度提升（P1）

- [ ] 3.1 替换字体方案（工业风格）
- [ ] 3.2 精简装饰性动画（保留功能性过渡，移除纯装饰效果）
- [ ] 3.3 优化 MonitorView 工具栏和诊断区布局
- [ ] 3.4 清理 console.log
- [ ] 3.5 修复 ECharts tooltip CSS 变量问题

### 阶段 4：品牌与体验优化（P2）

- [ ] 4.1 优化色彩体系（工业硬朗风格）
- [ ] 4.2 优化加载动画
- [ ] 4.3 优化登录页视觉

---

## 三、后端 API 变更记录

> 记录优化过程中发现的需要后端配合的接口调整

（暂无）

---

## 四、2026-04-07 已落地的视觉基线

- 全局字体由外网字体依赖切换为系统优先的中文工业字体栈：`HarmonyOS Sans SC / PingFang SC / Microsoft YaHei UI / Source Han Sans SC`
- 新增 `--font-ui`、`--font-display` 和控件高度令牌，统一按钮、标签、Tabs、单选按钮、分段切换的中文居中与尺寸
- `LayoutView`、`PageHeader` 的标题与壳层间距做了工业控制台化收敛，强调“稳态、清晰、长期使用不疲劳”
- 前端架构文档已补充视觉维护约定，后续页面优先复用公共壳层与基础件，不再在业务页散落修补控件对齐

## 五、技术约束

- Vue 3 + Vite + Element Plus + Pinia 技术栈不变
- 不改变路由结构和权限体系
- 不改变 WebSocket / HTTP 轮询通信协议
- 不改变 API 端点路径
- 兼容工业平板（1366x768 ~ 1920x1080 分辨率）
- 尊重现有暗色/亮色/工业三套主题机制
