# 相机视频与云台控制界面设计规范

## 1. 设计概述

### 1.1 设计理念
- **工业科技感**：深色主题配合霓虹蓝绿点缀，营造专业监控氛围
- **信息层次清晰**：视频为主，控制为辅，状态一目了然
- **操作直观**：大触控区域，明确的视觉反馈

### 1.2 核心原则
- 视频区域占据最大视觉空间
- 控制面板紧凑集成在右侧
- 所有操作在3步内完成
- 实时状态可视化

## 2. 布局结构

### 2.1 整体布局
```
┌─────────────────────────────────────┬─────────────┐
│                                     │  云台控制    │
│         视频主区域 (自适应)           │  ┌───────┐  │
│                                     │  │ 方向  │  │
│  ┌─────────────────────────────┐   │  │ 控制盘 │  │
│  │                             │   │  └───────┘  │
│  │      视频播放器              │   │  ┌───────┐  │
│  │                             │   │  │ 变焦  │  │
│  │   [叠加信息层]               │   │  │ 滑块  │  │
│  │   - 相机名称/LIVE标签        │   │  └───────┘  │
│  │   - 时间戳                   │   │  ┌───────┐  │
│  │   - 智能标注信息             │   │  │ 预置位 │  │
│  │   - 流状态信息               │   │  │ 网格  │  │
│  │                             │   │  └───────┘  │
│  └─────────────────────────────┘   │  ┌───────┐  │
│                                     │  │ 状态  │  │
│  ┌─────────────────────────────┐   │  │ 信息  │  │
│  │      底部工具栏              │   │  └───────┘  │
│  │  重置云台 | 全屏 | 截图 |    │   └─────────────┘
│  │  录像 | 视角切换             │
│  └─────────────────────────────┘
└─────────────────────────────────────────────────────┘
```

### 2.2 视频区域 (CameraPanel)
- **位置**：左侧主区域
- **尺寸**：自适应，最小高度600px
- **组成**：
  - VideoPlayer 组件
  - 叠加信息层（绝对定位）
  - 底部工具栏

### 2.3 控制侧边栏
- **位置**：右侧固定宽度320px
- **组成**：
  - 云台方向控制盘
  - 变焦垂直滑块
  - 预置位网格
  - 状态信息卡片

## 3. 视觉设计规范

### 3.1 颜色系统
```css
/* 背景色 */
--video-bg: linear-gradient(135deg, var(--bg-secondary) 0%, var(--bg-tertiary) 100%);
--overlay-bg: rgba(0, 0, 0, 0.6);
--control-bg: var(--panel-bg);

/* 文字色 */
--overlay-text: var(--text-white);
--control-text: var(--text-primary);
--status-text: var(--text-secondary);

/* 强调色 */
--accent-primary: var(--primary-color);      /* #00d4ff 霓虹蓝 */
--accent-success: var(--success-color);      /* #00d68f 青绿 */
--accent-warning: var(--warning-color);      /* #ff9f43 橙黄 */
--accent-danger: var(--danger-color);        /* #ff6b6b 红 */
```

### 3.2 字体规范
```css
/* 相机名称 */
font-size: 14px;
font-weight: 600;
color: var(--text-white);

/* 时间戳 */
font-family: var(--font-mono);
font-size: 13px;
font-weight: 600;

/* 状态信息 */
font-size: 12px;
color: var(--text-secondary);

/* 控制按钮 */
font-size: 12px;
font-weight: 500;
```

### 3.3 间距系统
```css
/* 容器间距 */
--panel-gap: 20px;
--section-gap: 16px;
--element-gap: 12px;
--item-gap: 8px;

/* 内边距 */
--overlay-padding: 16px;
--card-padding: 20px;
--button-padding: 10px 12px;
```

### 3.4 圆角与阴影
```css
/* 圆角 */
--video-radius: var(--radius-xl);      /* 16px */
--card-radius: var(--radius-xl);       /* 16px */
--button-radius: var(--radius-lg);     /* 12px */
--badge-radius: var(--radius-lg);      /* 12px */

/* 阴影 */
--video-shadow: inset 0 0 40px rgba(0, 0, 0, 0.3);
--overlay-shadow: 0 4px 20px rgba(0, 0, 0, 0.3);
--button-hover-shadow: 0 4px 12px rgba(0, 212, 255, 0.2);
```

## 4. 组件详细规范

### 4.1 视频叠加层 (VideoOverlay)

#### 顶部信息栏
- **位置**：左上角
- **内容**：相机图标 + 相机名称 + LIVE标签
- **样式**：
  ```css
  background: rgba(0, 0, 0, 0.6);
  backdrop-filter: blur(8px);
  border: 1px solid rgba(255, 255, 255, 0.1);
  border-radius: var(--radius-lg);
  padding: 8px 14px;
  ```

#### 时间戳
- **位置**：右上角
- **样式**：与顶部信息栏一致
- **字体**：等宽字体，突出时间感

#### 智能标注信息
- **位置**：左下角
- **内容**：最高点Z坐标、当前料堆名称
- **样式**：小型徽章式布局

#### 流状态信息
- **位置**：右下角
- **内容**：连接状态、分辨率、FPS
- **图标**：使用 Element Plus 图标

### 4.2 云台方向控制盘

#### 布局结构
```
    ┌─────┐
    │  ↑  │
    └─────┘
┌─────┬─────┬─────┐
│  ←  │  ●  │  →  │
└─────┴─────┴─────┘
    ┌─────┐
    │  ↓  │
    └─────┘
```

#### 按钮样式
```css
/* 方向按钮 */
width: 56px;
height: 56px;
border-radius: var(--radius-lg);
background: var(--bg-secondary);
border: 1px solid var(--panel-border-muted);
color: var(--text-secondary);
transition: all 0.2s ease;

/* 悬停状态 */
:hover {
  background: var(--bg-hover);
  border-color: var(--primary-color);
  color: var(--primary-color);
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0, 212, 255, 0.2);
}

/* 中心重置按钮 */
background: var(--gradient-primary);
color: var(--bg-primary);
```

#### 交互规范
- 支持鼠标按下持续移动
- 支持触摸操作
- 离开时自动停止
- 禁用状态透明度40%

### 4.3 变焦控制

#### 布局
- 垂直滑块设计
- 高度120px
- 左侧显示缩小图标，右侧显示放大图标

#### 滑块样式
```css
/* 轨道 */
background-color: var(--bg-tertiary);

/* 进度条 */
background: var(--gradient-primary);

/* 滑块按钮 */
border-color: var(--primary-color);
background: var(--bg-card);
```

### 4.4 预置位网格

#### 布局
- 2列网格
- 间距8px
- 按钮高度自适应

#### 按钮样式
```css
/* 默认 */
padding: 10px 12px;
border-radius: var(--radius-md);
background: var(--bg-secondary);
border: 1px solid var(--panel-border-muted);
font-size: 12px;

/* 激活 */
background: rgba(0, 212, 255, 0.15);
border-color: var(--primary-color);
color: var(--primary-color);
```

### 4.5 底部工具栏

#### 布局
- 水平排列
- 分组显示（按钮组）
- 居中对齐

#### 分组逻辑
1. **云台操作**：重置云台、全屏
2. **媒体操作**：截图、录像
3. **视角切换**：俯视、侧视、自由

## 5. 响应式适配

### 5.1 大屏 (>1200px)
- 左右布局，视频区域自适应
- 控制面板固定320px宽度

### 5.2 中屏 (768px - 1200px)
```css
.camera-panel {
  grid-template-columns: 1fr;
  grid-template-rows: 1fr auto;
}

.camera-sidebar {
  flex-direction: row;
  flex-wrap: wrap;
}
```

### 5.3 小屏 (<768px)
- 垂直堆叠布局
- 控制面板全宽
- 工具栏垂直排列

## 6. 动效规范

### 6.1 过渡时间
```css
--transition-fast: 0.15s;
--transition-base: 0.2s;
--transition-slow: 0.3s;
```

### 6.2 悬停效果
- 按钮：上移2px + 发光阴影
- 卡片：边框颜色变化
- 图标：颜色变为强调色

### 6.3 按压效果
```css
:active {
  transform: translateY(0) scale(0.95);
}
```

## 7. 无障碍设计

### 7.1 键盘操作
- 方向键控制云台
- Tab键遍历控制元素
- Enter/Space触发按钮

### 7.2 视觉辅助
- 禁用状态明确标识
- 焦点状态可见
- 对比度符合WCAG 2.1 AA标准

## 8. 实现文件

### 8.1 组件文件
- `src/components/monitor/CameraPanel.vue` - 主组件
- `src/components/VideoPlayer.vue` - 视频播放器
- `src/components/monitor/PtzControls.vue` - 原云台控制（保留兼容）

### 8.2 引用位置
- `src/views/MonitorView.vue` - 监控页面

## 9. 更新日志

### 2024-04-15
- 创建 CameraPanel 组件，整合视频和云台控制
- 重新设计布局结构，优化信息层次
- 统一视觉风格，符合工业科技主题
- 添加响应式适配支持
