# ZMYA 项目配色方案

> 智眸优安 - 智慧食堂综合管理系统 配色规范

---

## 一、主色调

### 1.1 品牌主色
| 颜色名称 | 色值 | 用途 |
|---------|------|------|
| 主色 | `#667eea` | 主要按钮、链接、强调元素 |
| 主色渐变 | `linear-gradient(135deg, #667eea 0%, #764ba2 100%)` | 品牌标识、重要卡片背景 |
| 主色悬停 | `#5a67d8` | 按钮悬停状态 |

### 1.2 功能色
| 颜色名称 | 色值 | 用途 |
|---------|------|------|
| 成功色 | `#10b981` | 成功状态、通过、已完成 |
| 成功色悬停 | `#059669` | 成功按钮悬停 |
| 警告色 | `#f59e0b` | 警告、待处理、提醒 |
| 警告色悬停 | `#d97706` | 警告按钮悬停 |
| 危险色 | `#ef4444` | 错误、删除、拒绝 |
| 危险色悬停 | `#dc2626` | 危险按钮悬停 |
| 信息色 | `#3b82f6` | 信息提示、进行中 |

---

## 二、状态标签配色

| 状态 | 背景色 | 文字色 |
|------|--------|--------|
| 待处理 (pending) | `#fef3c7` | `#92400e` |
| 已通过 (approved) | `#d1fae5` | `#065f46` |
| 已拒绝 (rejected) | `#fee2e2` | `#991b1b` |
| 进行中 (processing) | `#dbeafe` | `#1e40af` |
| 活跃 (active) | `#d1fae5` | `#065f46` |
| 非活跃 (inactive) | `#e5e7eb` | `#6b7280` |

---

## 三、警告/提示配色

| 类型 | 背景色 | 文字色 | 边框色 |
|------|--------|--------|--------|
| 警告 (warning) | `#fef3c7` | `#92400e` | `#fbbf24` |
| 危险 (danger) | `#fee2e2` | `#991b1b` | `#f87171` |
| 信息 (info) | `#dbeafe` | `#1e40af` | `#60a5fa` |
| 成功 (success) | `#d1fae5` | `#065f46` | `#34d399` |

---

## 四、文字颜色

| 颜色名称 | 色值 | 用途 |
|---------|------|------|
| 主要文字 | `#303133` | 标题、重要文字 |
| 常规文字 | `#606266` | 正文内容 |
| 次要文字 | `#909399` | 辅助说明、提示 |
| 占位文字 | `#C0C4CC` | 输入框占位符 |
| 正文默认 | `#333` | body 文字颜色 |

---

## 五、边框颜色

| 颜色名称 | 色值 | 用途 |
|---------|------|------|
| 基础边框 | `#DCDFE6` | 输入框、表格边框 |
| 浅边框 | `#E4E7ED` | 分割线、轻边框 |
| 更浅边框 | `#EBEEF5` | 卡片边框、内部分割 |
| 极浅边框 | `#F2F6FC` | 悬停背景、细微分割 |
| 轮廓按钮边框 | `#cbd5e1` | 轮廓按钮 |

---

## 六、背景颜色

| 颜色名称 | 色值 | 用途 |
|---------|------|------|
| 页面背景 | `#f5f7fa` | 页面整体背景 |
| 白色背景 | `#FFFFFF` | 卡片、弹窗、内容区 |
| 表格表头背景 | `#f9fafb` | 表格头部 |
| 表格悬停背景 | `#f9fafb` | 表格行悬停 |
| 按钮悬停背景 | `#f1f5f9` | 轮廓按钮悬停 |
| 滚动条轨道 | `#f1f1f1` | 滚动条背景 |
| 滚动条滑块 | `#c1c1c1` | 滚动条滑块默认 |
| 滚动条滑块悬停 | `#a8a8a8` | 滚动条滑块悬停 |

---

## 七、侧边栏配色

| 颜色名称 | 色值 | 用途 |
|---------|------|------|
| 侧边栏背景 | `#304156` | 左侧导航栏背景 |
| 侧边栏文字 | `#bfcbd9` | 菜单项文字 |
| 侧边栏激活 | `#409EFF` | 选中菜单项 |

---

## 八、深色主题配色

| 颜色名称 | 色值 | 用途 |
|---------|------|------|
| 主要文字 | `#E0E0E0` | 深色模式标题 |
| 常规文字 | `#B0B0B0` | 深色模式正文 |
| 次要文字 | `#808080` | 深色模式辅助文字 |
| 基础背景 | `#1a1a1a` | 深色模式页面背景 |
| 白色背景 | `#2d2d2d` | 深色模式卡片背景 |
| 基础边框 | `#444` | 深色模式边框 |
| 浅边框 | `#3a3a3a` | 深色模式分割线 |

---

## 九、CSS 变量定义

```css
:root {
  /* 主色调 */
  --primary-color: #667eea;
  --primary-gradient: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  --success-color: #10b981;
  --warning-color: #f59e0b;
  --danger-color: #ef4444;
  --info-color: #3b82f6;
  
  /* 布局尺寸 */
  --sidebar-width: 260px;
  --top-bar-height: 60px;
  
  /* 间距 */
  --spacing-xs: 4px;
  --spacing-sm: 8px;
  --spacing-md: 16px;
  --spacing-lg: 24px;
  --spacing-xl: 32px;
}
```

---

## 十、使用示例

### 10.1 按钮样式
```scss
.btn-primary {
  background: var(--primary-color);  /* #667eea */
  color: white;
  
  &:hover {
    background: #5a67d8;
  }
}

.btn-success {
  background: var(--success-color);  /* #10b981 */
  color: white;
  
  &:hover {
    background: #059669;
  }
}
```

### 10.2 状态标签
```scss
.status-badge.status-pending {
  background: #fef3c7;
  color: #92400e;
}

.status-badge.status-approved {
  background: #d1fae5;
  color: #065f46;
}
```

### 10.3 卡片样式
```scss
.card {
  background: white;
  border-radius: 8px;
  padding: 20px;
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.08);
  
  &:hover {
    box-shadow: 0 4px 16px rgba(0, 0, 0, 0.12);
  }
}
```

---

## 十一、配色预览

### 主色调
<div style="display: flex; gap: 10px; margin: 10px 0;">
  <div style="width: 100px; height: 50px; background: #667eea; color: white; display: flex; align-items: center; justify-content: center; border-radius: 4px;">主色 #667eea</div>
  <div style="width: 100px; height: 50px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; display: flex; align-items: center; justify-content: center; border-radius: 4px;">渐变</div>
</div>

### 功能色
<div style="display: flex; gap: 10px; margin: 10px 0;">
  <div style="width: 100px; height: 50px; background: #10b981; color: white; display: flex; align-items: center; justify-content: center; border-radius: 4px;">成功 #10b981</div>
  <div style="width: 100px; height: 50px; background: #f59e0b; color: white; display: flex; align-items: center; justify-content: center; border-radius: 4px;">警告 #f59e0b</div>
  <div style="width: 100px; height: 50px; background: #ef4444; color: white; display: flex; align-items: center; justify-content: center; border-radius: 4px;">危险 #ef4444</div>
  <div style="width: 100px; height: 50px; background: #3b82f6; color: white; display: flex; align-items: center; justify-content: center; border-radius: 4px;">信息 #3b82f6</div>
</div>

### 状态标签
<div style="display: flex; gap: 10px; margin: 10px 0;">
  <div style="padding: 4px 8px; background: #fef3c7; color: #92400e; border-radius: 12px; font-size: 12px;">待处理</div>
  <div style="padding: 4px 8px; background: #d1fae5; color: #065f46; border-radius: 12px; font-size: 12px;">已通过</div>
  <div style="padding: 4px 8px; background: #fee2e2; color: #991b1b; border-radius: 12px; font-size: 12px;">已拒绝</div>
  <div style="padding: 4px 8px; background: #dbeafe; color: #1e40af; border-radius: 12px; font-size: 12px;">进行中</div>
</div>

---

## 十二、文件位置

- **主样式文件**: `vue3-project/src/styles/index.scss`
- **变量定义文件**: `vue3-project/src/styles/variables.scss`

---

## 十三、多主题配色方案

系统支持多种配色主题，可根据应用场景切换。

### 13.1 主题对比

| 主题名称 | 主色调 | 适用场景 | 风格特点 |
|---------|--------|----------|----------|
| **默认主题** | 紫蓝渐变 `#667eea` | 智慧食堂、服务类应用 | 现代、柔和、年轻化 |
| **工业蓝主题** | 深蓝 `#1e3a8a` | 工业控制、料场管理 | 稳重、专业、可靠 |

### 13.2 工业蓝主题配色

#### 主色调
| 颜色名称 | 色值 | 用途 |
|---------|------|------|
| 主色 | `#1e3a8a` | 主要按钮、链接、强调元素 |
| 主色渐变 | `linear-gradient(135deg, #1e3a8a 0%, #3b82f6 100%)` | 品牌标识、重要卡片背景 |
| 主色悬停 | `#1e40af` | 按钮悬停状态 |
| 主色浅 | `#dbeafe` | 轻量背景、标签 |

#### 功能色（工业蓝主题）
| 颜色名称 | 色值 | 用途 |
|---------|------|------|
| 成功色 | `#059669` | 成功状态、正常运行 |
| 成功色悬停 | `#047857` | 成功按钮悬停 |
| 警告色 | `#d97706` | 警告、注意、待机 |
| 警告色悬停 | `#b45309` | 警告按钮悬停 |
| 危险色 | `#dc2626` | 错误、停止、紧急 |
| 危险色悬停 | `#b91c1c` | 危险按钮悬停 |
| 信息色 | `#2563eb` | 信息提示、进行中 |

#### 状态标签配色（工业蓝主题）
| 状态 | 背景色 | 文字色 |
|------|--------|--------|
| 运行中 (running) | `#dbeafe` | `#1e40af` |
| 正常 (normal) | `#d1fae5` | `#065f46` |
| 报警 (alarm) | `#fef3c7` | `#92400e` |
| 故障 (fault) | `#fee2e2` | `#991b1b` |
| 待机 (standby) | `#e0e7ff` | `#3730a3` |
| 离线 (offline) | `#f3f4f6` | `#6b7280` |

#### 文字颜色（工业蓝主题）
| 颜色名称 | 色值 | 用途 |
|---------|------|------|
| 主要文字 | `#1f2937` | 标题、重要文字 |
| 常规文字 | `#4b5563` | 正文内容 |
| 次要文字 | `#6b7280` | 辅助说明、提示 |
| 占位文字 | `#9ca3af` | 输入框占位符 |
| 正文默认 | `#374151` | body 文字颜色 |

#### 背景颜色（工业蓝主题）
| 颜色名称 | 色值 | 用途 |
|---------|------|------|
| 页面背景 | `#f8fafc` | 页面整体背景 |
| 卡片背景 | `#ffffff` | 卡片、弹窗、内容区 |
| 表格表头背景 | `#f1f5f9` | 表格头部 |
| 表格悬停背景 | `#e2e8f0` | 表格行悬停 |
| 侧边栏背景 | `#0f172a` | 左侧导航栏背景 |
| 侧边栏文字 | `#cbd5e1` | 菜单项文字 |
| 侧边栏激活 | `#3b82f6` | 选中菜单项 |

#### 边框颜色（工业蓝主题）
| 颜色名称 | 色值 | 用途 |
|---------|------|------|
| 基础边框 | `#d1d5db` | 输入框、表格边框 |
| 浅边框 | `#e5e7eb` | 分割线、轻边框 |
| 更浅边框 | `#f3f4f6` | 卡片边框、内部分割 |

### 13.3 主题切换方法

```scss
// 默认主题（智慧食堂）
$theme: 'default';

// 工业蓝主题（料场管理）
$theme: 'industrial';

// 根据主题变量导入不同配色
@if $theme == 'industrial' {
  @import 'themes/industrial-blue';
} @else {
  @import 'themes/default';
}
```

### 13.4 主题预览对比

#### 默认主题（紫蓝渐变）
<div style="display: flex; gap: 10px; margin: 10px 0;">
  <div style="width: 120px; height: 50px; background: #667eea; color: white; display: flex; align-items: center; justify-content: center; border-radius: 4px; font-weight: bold;">默认主色</div>
  <div style="width: 120px; height: 50px; background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; display: flex; align-items: center; justify-content: center; border-radius: 4px; font-weight: bold;">渐变</div>
</div>

#### 工业蓝主题
<div style="display: flex; gap: 10px; margin: 10px 0;">
  <div style="width: 120px; height: 50px; background: #1e3a8a; color: white; display: flex; align-items: center; justify-content: center; border-radius: 4px; font-weight: bold;">工业蓝主色</div>
  <div style="width: 120px; height: 50px; background: linear-gradient(135deg, #1e3a8a 0%, #3b82f6 100%); color: white; display: flex; align-items: center; justify-content: center; border-radius: 4px; font-weight: bold;">渐变</div>
</div>

### 13.5 暗黑模式配色

#### 主色调
| 颜色名称 | 色值 | 用途 |
|---------|------|------|
| 主色 | `#3b82f6` | 主要按钮、链接、强调元素 |
| 主色悬停 | `#60a5fa` | 按钮悬停状态 |
| 主色浅 | `#1e3a8a` | 轻量背景、标签 |

#### 功能色（暗黑模式）
| 颜色名称 | 色值 | 用途 |
|---------|------|------|
| 成功色 | `#10b981` | 成功状态、正常运行 |
| 成功色悬停 | `#34d399` | 成功按钮悬停 |
| 警告色 | `#f59e0b` | 警告、注意 |
| 警告色悬停 | `#fbbf24` | 警告按钮悬停 |
| 危险色 | `#ef4444` | 错误、停止、紧急 |
| 危险色悬停 | `#f87171` | 危险按钮悬停 |
| 信息色 | `#60a5fa` | 信息提示、进行中 |

#### 背景颜色（暗黑模式）
| 颜色名称 | 色值 | 用途 |
|---------|------|------|
| 页面背景 | `#0f172a` | 页面整体背景 |
| 卡片背景 | `#1e293b` | 卡片、弹窗、内容区 |
|  elevated背景 | `#334155` | 提升层级、下拉菜单 |
| 表格表头背景 | `#1e293b` | 表格头部 |
| 表格悬停背景 | `#334155` | 表格行悬停 |
| 侧边栏背景 | `#020617` | 左侧导航栏背景 |
| 侧边栏文字 | `#94a3b8` | 菜单项文字 |
| 侧边栏激活 | `#3b82f6` | 选中菜单项 |

#### 文字颜色（暗黑模式）
| 颜色名称 | 色值 | 用途 |
|---------|------|------|
| 主要文字 | `#f1f5f9` | 标题、重要文字 |
| 常规文字 | `#cbd5e1` | 正文内容 |
| 次要文字 | `#94a3b8` | 辅助说明、提示 |
| 占位文字 | `#64748b` | 输入框占位符 |
| 禁用文字 | `#475569` | 禁用状态文字 |

#### 边框颜色（暗黑模式）
| 颜色名称 | 色值 | 用途 |
|---------|------|------|
| 基础边框 | `#334155` | 输入框、表格边框 |
| 浅边框 | `#1e293b` | 分割线、轻边框 |
| 更浅边框 | `#0f172a` | 细微分割 |

### 13.6 三种主题对比

| 主题名称 | 主色调 | 背景色 | 适用场景 | 特点 |
|---------|--------|--------|----------|------|
| **默认主题** | `#667eea` 紫蓝 | `#f5f7fa` 浅灰 | 智慧食堂、服务类应用 | 现代、柔和、年轻化 |
| **工业蓝主题** | `#1e3a8a` 深蓝 | `#f8fafc` 浅灰 | 工业控制、料场管理 | 稳重、专业、可靠 |
| **暗黑模式** | `#3b82f6` 亮蓝 | `#0f172a` 深蓝黑 | 夜间操作、控制室 | 护眼、低疲劳、专注 |

### 13.7 使用建议

| 应用场景 | 推荐主题 | 原因 |
|---------|---------|------|
| 智慧食堂、餐饮服务 | 默认主题 | 友好、现代、亲和力强 |
| 工业控制、料场管理 | 工业蓝主题 | 稳重、专业、长时间操作不易疲劳 |
| 数据监控、仪表盘 | 工业蓝主题 | 对比度高、数据清晰易读 |
| 移动端应用 | 默认主题 | 色彩鲜明、触摸反馈明显 |
| 大屏展示、指挥中心 | 工业蓝主题 | 沉稳大气、适合长时间观看 |
| 夜间操作、低光环境 | 暗黑模式 | 减少眼部疲劳、降低屏幕亮度 |
| 控制室、监控中心 | 暗黑模式 | 专业感强、数据突出显示 |

### 13.8 主题预览

#### 默认主题
<div style="display: flex; gap: 10px; margin: 10px 0;">
  <div style="width: 100px; height: 50px; background: #667eea; color: white; display: flex; align-items: center; justify-content: center; border-radius: 4px; font-weight: bold;">默认</div>
  <div style="width: 100px; height: 50px; background: #f5f7fa; color: #333; display: flex; align-items: center; justify-content: center; border-radius: 4px; font-weight: bold; border: 1px solid #ddd;">背景</div>
</div>

#### 工业蓝主题
<div style="display: flex; gap: 10px; margin: 10px 0;">
  <div style="width: 100px; height: 50px; background: #1e3a8a; color: white; display: flex; align-items: center; justify-content: center; border-radius: 4px; font-weight: bold;">工业蓝</div>
  <div style="width: 100px; height: 50px; background: #f8fafc; color: #333; display: flex; align-items: center; justify-content: center; border-radius: 4px; font-weight: bold; border: 1px solid #ddd;">背景</div>
</div>

#### 暗黑模式
<div style="display: flex; gap: 10px; margin: 10px 0;">
  <div style="width: 100px; height: 50px; background: #3b82f6; color: white; display: flex; align-items: center; justify-content: center; border-radius: 4px; font-weight: bold;">暗黑</div>
  <div style="width: 100px; height: 50px; background: #0f172a; color: white; display: flex; align-items: center; justify-content: center; border-radius: 4px; font-weight: bold; border: 1px solid #334155;">背景</div>
</div>

---

*生成时间: 2026-03-15*
*项目: 智眸优安 (ZMYA) - 智慧食堂综合管理系统 / 抓斗作业引导及盘存系统*
