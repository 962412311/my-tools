# Monitor Layout Redesign

**Date:** 2026-04-16

## Goal

在不改后端接口契约的前提下，重构实时监控页前端布局，让页面优先服务值班操作员，并把视频与点云提升为同级双主舞台。详细链路、诊断、日志和低频工具下沉为可折叠工作区，降低首屏噪声，同时兼顾宽屏桌面和 14-16 寸笔记本。

## Context

- 监控页是系统核心主链路，文档和现场 SOP 都要求用户先看链路，再做截图、录像、PTZ、写 PLC 等动作。
- 当前 [frontend/src/views/MonitorView.vue](/mnt/d/QtWorkData/GOGS/frontend/src/views/MonitorView.vue:1) 将值守、联调、诊断、日志、工具全部放在同一层级，导致右侧栏过重，双主舞台不够明确。
- 全局视觉体系已由 [PageHeader](/mnt/d/QtWorkData/GOGS/frontend/src/components/layout/PageHeader.vue:1)、[SectionCard](/mnt/d/QtWorkData/GOGS/frontend/src/components/layout/SectionCard.vue:1)、`panel-bg` / `panel-border-muted` 等 token 定义，监控页必须延续这套语言，而不是另起一套视觉系统。
- 文档明确监控页需要高信息密度但层次清楚，且要求桌面和笔记本下都成立。

## Users And Primary Workflow

**Primary user:** 值班操作员

**Primary workflow:**
1. 进入监控页后先看实时画面和点云判断现场状态。
2. 快速确认最高点、基础运行态和是否需要 PTZ 微调。
3. 仅在发现异常时，展开链路状态、设备诊断和日志排查。
4. 需要动作时执行录像、截图、全屏、复制坐标或写 PLC。

## Design Direction

- 视频与点云并重
- 值班优先，联调次之
- 轻量现代化，但继承现有工业控制台深色骨架
- 详细信息下沉，不把首屏做成告警墙

## Layout Model

监控页采用三段式工作台：

1. **PageHeader**
2. **WorkbenchToolbar**
3. **Monitor Workbench**

### 1. PageHeader

继续沿用现有 `PageHeader` 组件。

保留：
- `eyebrow`: 实时监控
- `title`: 作业监控与现场处置
- `description`: 保持“视频、点云、处置动作可视”语义

`meta` 仅保留 4 项：
- 当前视图
- 录像状态
- 智能标注
- 系统时间

`actions` 仅保留 3 个高频动作：
- 录像/停止录像
- 截图
- 复制视频摘要

不再在头部堆叠链路、插件、录像健康等解释性细节。

### 2. WorkbenchToolbar

工具栏保留三组：

- 搜索区
- 视图切换区
- 快捷操作区

但快捷操作重新分层：
- 首层保留值班高频入口
- 低频动作允许进入下沉工作区的“扩展工具”

保留的视图模式：
- `split`
- `video`
- `pointcloud`
- `yard`

### 3. Monitor Workbench

采用三段：

- **双主舞台**
- **轻量动作栏**
- **下沉折叠工作区**

## Dual-Stage Layout

### Desktop / Wide Screen

首屏采用三列：

- 视频舞台
- 点云舞台
- 轻栏

建议比例：
- 视频：`1.18fr`
- 点云：`0.94fr`
- 轻栏：`0.62fr`

### Laptop

切换为：
- 视频在上
- 点云在下
- 轻栏变成 3 张横向卡片

避免继续硬保三列，防止主舞台被压扁。

### Narrow / Tablet

切换为：
- 单主舞台
- 顶部视图切换
- 轻栏和详细区全部下沉

## Stage Responsibilities

### Video Stage

视频舞台分三层：

- 顶层浮条：摄像头标识、当前时间、Live 状态
- 中层主体：纯视频画面
- 底层动作条：录像、截图、全屏、重置云台

智能标注只保留少量高优先信息：
- 最高点 Z
- 关联料堆（如果可用）

视频舞台不再承担复杂诊断解释。

### Point Cloud Stage

点云舞台分三层：

- 顶层浮条：点云来源、点数、帧率
- 中层主体：Three.js 点云视口
- 底层控制条：来源切换、视角切换、显示开关、点大小

已选点信息从现有统计胶囊中独立，避免整排 overlay 被长文本拉坏。

### Light Rail

轻栏只保留三块：

- 运行态概览
- 最高点与处置
- PTZ 快控

不再在轻栏放：
- 视频链路明细
- MediaMTX 诊断
- 实时日志
- 搜索结果

## Lower Workbench

下沉工作区由 4 个折叠分区构成：

1. `链路状态`
2. `设备诊断`
3. `日志与搜索`
4. `扩展工具`

### Default Expansion

默认展开：
- `链路状态`

默认折叠：
- `设备诊断`
- `日志与搜索`
- `扩展工具`

### Chain Status

这里承接文档要求的完整链路信息：
- 实时链路
- 链路异常
- MediaMTX
- 端口探测
- 配置源
- 视频基线
- 视频自检
- 录像前提
- 录像健康
- 插件摘要
- 缺失插件
- 录像编码

首屏不重复呈现这些字段，只在折叠区保留完整解释。

### Device Diagnostics

容纳现有 `DiagnosticsPanel` 和补扫操作。

### Logs And Search

容纳：
- 搜索结果
- 实时日志
- 高级搜索入口

### Extension Tools

容纳低频工具：
- 批量盘点
- 视角预设
- 边界导入导出

## Interaction Rules

- 首屏永远可直接执行：录像、截图、全屏、重置云台、复制坐标、写 PLC。
- 低频工具不再挤占双主舞台周边位置。
- 头部简报、轻栏卡片、下沉工作区之间不重复表达同一状态。
- 一类信息只能有一个主落点：
  - 头部：摘要
  - 下沉区：详细解释
  - 日志：事件记录

## Component Boundaries

本次前端优先重构限定在以下边界：

- [frontend/src/views/MonitorView.vue](/mnt/d/QtWorkData/GOGS/frontend/src/views/MonitorView.vue:1)
- [frontend/src/components/monitor/CameraPanel.vue](/mnt/d/QtWorkData/GOGS/frontend/src/components/monitor/CameraPanel.vue:1)
- [frontend/src/components/monitor/DiagnosticsPanel.vue](/mnt/d/QtWorkData/GOGS/frontend/src/components/monitor/DiagnosticsPanel.vue:1)
- 新增监控页下沉工作区或折叠容器组件

不在本轮改动：
- 后端视频、PTZ、录像、补扫接口结构
- 点云流来源与 WebSocket 语义
- 监控页之外的业务逻辑

## Testing Strategy

### Contract Tests

补充前端契约测试，锁住以下要求：
- 双主舞台仍存在视频和点云两个主区
- 轻栏只承载值班核心卡片
- 链路与诊断进入下沉折叠区
- 低频工具从首屏动作下沉
- 宽屏与笔记本布局断点存在

### Frontend Verification

需要验证：
- `split / video / pointcloud / yard` 四种模式仍能切换
- 视频播放链路没有被布局重构打断
- 点云 Canvas 在布局切换后仍正确重建
- PTZ 快控仍能触发现有前端动作
- 折叠区展开/收起稳定
- 宽屏和笔记本断点显示合理

## Risks

- `MonitorView.vue` 已非常大，继续塞折叠逻辑会让文件更重，因此本轮允许抽出新的监控布局组件。
- 现有测试对 `MonitorView` 文本结构有很多正则断言，布局重构必须同步更新契约测试，避免误报。
- 不能把链路字段直接“视觉下沉”后又失去现场可见性，必须保留默认展开的 `链路状态` 分区。

## Out Of Scope

- 后端字段改名
- 新增监控业务功能
- 重写 `VideoPlayer` 或点云渲染内核
- 远控页同步重构
