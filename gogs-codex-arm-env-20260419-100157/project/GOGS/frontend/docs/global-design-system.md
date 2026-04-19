# 全局设计系统规范

## 1. 设计哲学

### 1.1 核心定位
- **风格定位**：工业科技感深色主题
- **设计理念**：炫酷而简约、成熟、克制、高级
- **视觉语言**：深色背景 + 霓虹蓝绿点缀 + 金属质感

### 1.2 设计原则
1. **深色优先**：所有界面基于深色背景设计，禁止浅色主题
2. **信息密度**：高信息密度，减少不必要的留白
3. **视觉层次**：通过颜色明度和发光效果建立清晰的层级
4. **一致性**：所有组件遵循统一的设计语言
5. **功能性优先**：每个视觉元素都服务于功能

## 2. 色彩系统

### 2.1 主色调
```css
/* 主色 - 工业霓虹蓝 */
--primary-color: #00d4ff;
--primary-light: #4de8ff;
--primary-dark: #00a8cc;
--primary-gradient: linear-gradient(135deg, #00a8cc 0%, #00d4ff 50%, #4de8ff 100%);

/* 强调色 - 电光蓝 */
--accent-color: #0080ff;
--highlight-color: #00ffff;
```

### 2.2 功能色
```css
/* 成功 - 青绿 */
--success-color: #00e676;
--success-gradient: linear-gradient(135deg, #00c853 0%, #00e676 100%);

/* 警告 - 橙黄 */
--warning-color: #ffab00;
--warning-gradient: linear-gradient(135deg, #ff9100 0%, #ffab00 100%);

/* 危险 - 红 */
--danger-color: #ff5252;
--danger-gradient: linear-gradient(135deg, #ff1744 0%, #ff5252 100%);

/* 信息 - 蓝 */
--info-color: #448aff;
--info-gradient: linear-gradient(135deg, #2979ff 0%, #448aff 100%);
```

### 2.3 背景色阶
```css
/* 深层背景 */
--bg-primary: #050a14;      /* 最深，用于页面背景 */
--bg-secondary: #0a1120;    /* 次级，用于卡片背景 */
--bg-tertiary: #111a2e;     /* 第三层，用于悬停状态 */
--bg-card: #0d1525;         /* 卡片背景 */
--bg-elevated: #142038;     /* 提升层 */
--bg-hover: #1a2842;        /* 悬停背景 */
--bg-pressed: #223355;      /* 按压背景 */
```

### 2.4 文字色阶
```css
--text-primary: #e8f4fc;    /* 主要文字，接近白色 */
--text-secondary: #b8d4e8;  /* 次要文字 */
--text-tertiary: #7a9ab8;   /* 辅助文字 */
--text-disabled: #4a5a70;   /* 禁用文字 */
--text-white: #ffffff;      /* 纯白，用于强调 */
```

### 2.5 边框色阶
```css
--border-color: #1a2c44;           /* 基础边框 */
--border-light: #243a5c;           /* 亮边框 */
--panel-border-strong: rgba(0, 212, 255, 0.25);   /* 强调边框 */
--panel-border-muted: rgba(0, 212, 255, 0.08);    /* 弱化边框 */
```

## 3. 字体系统

### 3.1 字体族
```css
/* 界面字体 */
--font-ui: 'HarmonyOS Sans SC', 'PingFang SC', 'Hiragino Sans GB', 'Microsoft YaHei UI', sans-serif;

/* 展示字体 */
--font-display: 'DIN Alternate', 'Bahnschrift', 'Avenir Next Condensed', 'HarmonyOS Sans SC', sans-serif;

/* 等宽字体 */
--font-mono: 'JetBrains Mono', 'SFMono-Regular', 'Cascadia Mono', 'Roboto Mono', Consolas, monospace;
```

### 3.2 字号规范
```css
--font-size-xs: 11px;       /* 标签、徽章 */
--font-size-sm: 12px;       /* 辅助文字 */
--font-size-base: 14px;     /* 正文 */
--font-size-lg: 16px;       /* 小标题 */
--font-size-xl: 18px;       /* 中标题 */
--font-size-2xl: 20px;      /* 大标题 */
--font-size-3xl: 24px;      /* 页面标题 */
--font-size-4xl: 32px;      /* 展示标题 */
```

### 3.3 字重规范
- **常规**：400（正文）
- **中等**：500（强调文字）
- **半粗**：600（标题、按钮）
- **粗体**：700（大标题）

### 3.4 行高规范
```css
--line-height-tight: 1.3;    /* 标题 */
--line-height-base: 1.6;     /* 正文 */
--line-height-relaxed: 1.75; /* 宽松排版 */
```

## 4. 间距系统

### 4.1 基础间距
```css
--space-xs: 4px;
--space-sm: 8px;
--space-md: 12px;
--space-lg: 16px;
--space-xl: 20px;
--space-2xl: 24px;
--space-3xl: 32px;
--space-4xl: 40px;
```

### 4.2 组件间距
- **卡片内边距**：20px-24px
- **按钮内边距**：水平16px，垂直根据尺寸调整
- **表单字段间距**：16px-20px
- **列表项间距**：12px-16px

## 5. 圆角系统

```css
--radius-xs: 2px;       /* 小标签 */
--radius-sm: 4px;       /* 输入框 */
--radius-md: 8px;       /* 按钮 */
--radius-lg: 12px;      /* 卡片 */
--radius-xl: 16px;      /* 大卡片 */
--radius-2xl: 20px;     /* 弹窗 */
--radius-full: 9999px;  /* 胶囊形 */
```

## 6. 阴影系统

### 6.1 层级阴影
```css
--shadow-xs: 0 1px 2px rgba(0, 0, 0, 0.50);
--shadow-sm: 0 2px 8px rgba(0, 0, 0, 0.45);
--shadow-md: 0 4px 16px rgba(0, 0, 0, 0.50);
--shadow-lg: 0 8px 24px rgba(0, 0, 0, 0.55);
--shadow-xl: 0 12px 32px rgba(0, 0, 0, 0.60);
```

### 6.2 发光阴影
```css
--shadow-primary: 0 4px 16px rgba(0, 212, 255, 0.25);
--shadow-success: 0 4px 16px rgba(0, 230, 118, 0.20);
--shadow-warning: 0 4px 16px rgba(255, 171, 0, 0.20);
--shadow-danger: 0 4px 16px rgba(255, 82, 82, 0.20);
```

### 6.3 光晕效果
```css
--glow-primary: 0 0 20px rgba(0, 212, 255, 0.30);
--glow-success: 0 0 20px rgba(0, 230, 118, 0.25);
--glow-warning: 0 0 20px rgba(255, 171, 0, 0.25);
--glow-danger: 0 0 20px rgba(255, 82, 82, 0.25);
```

## 7. 动效系统

### 7.1 过渡时间
```css
--transition-fast: 120ms cubic-bezier(0.25, 0.1, 0.25, 1);
--transition-base: 180ms cubic-bezier(0.25, 0.1, 0.25, 1);
--transition-slow: 280ms cubic-bezier(0.25, 0.1, 0.25, 1);
--transition-spring: 500ms cubic-bezier(0.34, 1.56, 0.64, 1);
```

### 7.2 悬停效果
- **按钮**：上移1px + 发光阴影
- **卡片**：边框颜色变亮 + 外发光
- **列表项**：背景色变亮

### 7.3 按压效果
```css
:active {
  transform: translateY(0) scale(0.98);
  transition-duration: 80ms;
}
```

## 8. 组件规范

### 8.1 卡片 (Card)
```css
.el-card {
  border-radius: var(--radius-xl);
  border: 1px solid var(--panel-border-muted);
  background:
    linear-gradient(180deg, rgba(0, 212, 255, 0.03) 0%, transparent 80px),
    var(--panel-bg);
  box-shadow:
    0 4px 20px rgba(0, 0, 0, 0.4),
    inset 0 1px 0 rgba(0, 212, 255, 0.08);
}
```

### 8.2 按钮 (Button)
- **默认**：深色背景 + 边框
- **主要**：渐变背景 + 发光效果
- **危险**：红色渐变
- **文字**：透明背景 + 悬停下划线

### 8.3 输入框 (Input)
```css
.el-input__wrapper {
  background-color: var(--bg-secondary);
  border: 1px solid var(--panel-border-muted);
  border-radius: var(--radius-md);
  box-shadow: inset 0 2px 4px rgba(0, 0, 0, 0.3);
}
```

### 8.4 表格 (Table)
- **表头**：深色背景 + 底部边框
- **行**：交替背景色（可选）
- **悬停行**：半透明主色背景

### 8.5 标签 (Tag)
- **默认**：半透明背景 + 对应颜色边框
- **深色**：深色背景 + 发光效果
- **浅色**：浅色文字 + 透明背景

### 8.6 弹窗 (Dialog)
- **背景**：半透明遮罩
- **容器**：深色卡片 + 顶部渐变装饰
- **关闭按钮**：右上角，悬停变主色

## 9. 布局规范

### 9.1 页面结构
```
┌─────────────────────────────────────┐
│  顶部导航栏 (68px)                   │
├──────────┬──────────────────────────┤
│          │                          │
│  侧边栏   │      主内容区             │
│ (260px)  │    (自适应剩余宽度)        │
│          │                          │
└──────────┴──────────────────────────┘
```

### 9.2 栅格系统
- **容器最大宽度**：1520px
- **栅格数**：24列
- **间距**：16px-24px

### 9.3 响应式断点
- **大屏**：> 1200px（完整布局）
- **中屏**：768px - 1200px（侧边栏可收起）
- **小屏**：< 768px（单列布局）

## 10. 图标规范

### 10.1 图标库
- **主图标库**：Element Plus Icons
- **备用**：自定义 SVG 图标

### 10.2 图标尺寸
- **小**：14px（内联文字）
- **中**：16px（按钮、列表）
- **大**：20px（独立图标）
- **超大**：24px（导航、标题）

### 10.3 图标颜色
- **默认**：继承文字颜色
- **强调**：主色/功能色
- **禁用**：--text-disabled

## 11. 特殊效果

### 11.1 背景效果
```css
/* 工业网格 */
body::before {
  background-image:
    linear-gradient(rgba(0, 212, 255, 0.03) 1px, transparent 1px),
    linear-gradient(90deg, rgba(0, 212, 255, 0.03) 1px, transparent 1px);
  background-size: 48px 48px;
}

/* 顶部光晕 */
body::after {
  background: radial-gradient(ellipse at center, rgba(0, 212, 255, 0.06) 0%, transparent 70%);
}
```

### 11.2 文字效果
```css
/* 发光文字 */
.text-glow {
  text-shadow: 0 0 10px rgba(0, 212, 255, 0.50), 0 0 20px rgba(0, 212, 255, 0.30);
}
```

### 11.3 边框效果
```css
/* 发光边框 */
.border-glow {
  border-color: rgba(0, 212, 255, 0.30);
  box-shadow: 0 0 0 1px rgba(0, 212, 255, 0.15), inset 0 0 20px rgba(0, 212, 255, 0.05);
}
```

## 12. 无障碍规范

### 12.1 对比度
- **正文**：至少 4.5:1
- **大文字**：至少 3:1
- **交互元素**：至少 3:1

### 12.2 焦点状态
- 所有可交互元素必须有可见焦点指示器
- 焦点环颜色：--primary-color
- 焦点环宽度：2px

### 12.3 键盘导航
- 所有功能必须可通过键盘访问
- Tab顺序符合视觉顺序
- 提供跳过导航链接

## 13. 文件组织

### 13.1 样式文件
```
src/
├── styles/
│   ├── theme.css          # 主题变量
│   └── utilities.css      # 工具类
├── style.css              # 全局样式 + Element Plus 覆盖
└── components/
    └── *.vue              # 组件样式（scoped）
```

### 13.2 设计文档
```
docs/
├── global-design-system.md    # 本文件
├── camera-ptz-design-spec.md  # 相机云台设计规范
└── refactoring-issues.md      # 重构问题记录
```

## 14. 使用约束

### 14.1 禁止事项
1. **禁止**使用浅色主题
2. **禁止**使用纯黑色背景（使用 #050a14）
3. **禁止**使用纯白色文字（使用 #e8f4fc）
4. **禁止**使用硬编码颜色值
5. **禁止**使用系统默认字体

### 14.2 必须遵循
1. **必须**使用 CSS 变量
2. **必须**使用主题色作为强调色
3. **必须**保持足够的对比度
4. **必须**添加过渡动画
5. **必须**测试键盘导航

### 14.3 推荐实践
1. 使用 `var(--radius-xl)` 保持圆角一致
2. 使用 `var(--shadow-md)` 保持阴影一致
3. 使用 `var(--transition-base)` 保持动效一致
4. 使用 `var(--space-lg)` 保持间距一致

## 15. 更新记录

### 2024-04-15
- 创建全局设计系统规范
- 定义色彩、字体、间距、圆角、阴影系统
- 规范组件样式和布局
- 添加无障碍和文件组织规范
