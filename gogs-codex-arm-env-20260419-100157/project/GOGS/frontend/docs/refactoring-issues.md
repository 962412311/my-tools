# 前端重构问题记录文档

> 历史记录说明：本文档反映 2026-04-03 早期工业化改版阶段的设计取向和问题判断，不再作为当前现行前端规范或任务入口。
> 当前请优先参考：`frontend/docs/todo.md`、`frontend/docs/frontend-architecture.md`、`docs/gogs-rtk.md`。

## 重构目标
- 删除浅色主题，只保留深色主题
- 整体风格：炫酷而简约、成熟、克制、高级、工业科技感
- 覆盖所有界面、页面、公共组件

## 已完成重构内容

### 1. 主题系统重构 ✅
- [x] `stores/theme.js` - 简化为仅 industrial 主题，移除 light/dark/auto 切换
- [x] `styles/theme.css` - 全新工业科技配色，青色主色调
- [x] `style.css` - 全局样式适配深色工业主题
- [x] `main.js` - 初始化逻辑更新
- [x] `components/ThemeSwitch.vue` - 改为静态主题指示器

### 2. 布局组件重构 ✅
- [x] `views/LayoutView.vue` - 侧边栏、顶部栏工业风格化
  - 青色发光边框效果
  - 工业网格背景
  - 脉冲动画状态指示器
  - 玻璃态效果

### 3. 页面重构 ✅
- [x] `views/LoginView.vue` - 登录页全新工业风格
  - 扫描线效果
  - 发光渐变背景
  - 工业风卡片设计
  - 动态分隔线动画

### 4. 公共组件重构 ✅
- [x] `components/SystemStatus.vue` - 系统状态指示器
- [x] `components/ConnectionStatus.vue` - 连接状态指示器
  - 脉冲发光效果
  - 状态色彩区分

## 设计系统规范

### 色彩体系
```css
--primary-color: #00d4ff;        /* 工业青 */
--success-color: #00e676;        /* 科技绿 */
--warning-color: #ffab00;        /* 警示橙 */
--danger-color: #ff5252;         /* 危险红 */
--bg-primary: #050a14;           /* 深邃黑 */
--bg-card: #0d1525;              /* 卡片黑 */
--text-primary: #e8f4fc;         /* 主文字 */
```

### 视觉效果
- 青色发光边框 (box-shadow glow)
- 工业网格背景 (grid pattern)
- 扫描线效果 (scanlines)
- 脉冲动画 (pulse animation)
- 玻璃态 (glassmorphism)

### 阴影层级
- 主阴影: 0 4px 20px rgba(0, 0, 0, 0.4)
- 发光阴影: 0 0 30px rgba(0, 212, 255, 0.15)
- 悬浮阴影: 0 8px 32px rgba(0, 0, 0, 0.5)

## 重构完成状态
**全部完成** - 所有界面已统一为工业科技深色风格
