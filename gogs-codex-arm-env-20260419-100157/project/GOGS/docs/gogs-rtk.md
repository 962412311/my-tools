# GOGS RTK（快速上手包）

## 概述
这份 RTK 用来帮新会话、新同事或回归维护的人在较短时间内建立共同上下文，优先回答四个问题：

1. 这个系统现在的主线是什么。
2. 关键代码和关键文档分别在哪。
3. 常用开发、部署、验活入口是什么。
4. 配置中心里“雷达配置”现在到底落在哪。

补充说明：
- 这里的“GOGS RTK”指的是仓库级快速上手包。
- 在 Codex / CLI 会话里执行命令时，仍然统一用 `rtk` 作为命令前缀，例如 `rtk git status`。

## 背景
仓库里同时存在根 `README.md`、`docs/*`、`DOC/*` 和部分历史说明书。它们分别有价值，但如果不先收口阅读顺序，很容易出现：

- 文档看了很多，仍不清楚主线
- 旧 `ConfigView` 认知和新配置中心路由混在一起
- 知道有雷达配置，但不知道它被拆到了哪个域

## 目标
- 5 到 10 分钟内建立系统全貌
- 15 到 30 分钟内找到对应代码和运行入口
- 避免继续按旧“通信配置/雷达配置”心智找新配置中心

## 范围
包含：
- 当前项目主线
- 推荐阅读顺序
- 仓库结构与常用命令
- 配置中心的真实落点

不包含：
- 全量算法细节
- 全量现场联调流程
- 旧版说明书逐页对照

## 当前主线
当前项目已经收口到这条主线：

- 后端：`Qt 6.2.4 + C++17`
- 前端：`Vue 3 + Vite`
- 部署目标：`ARM Debian 11 / ARM64`
- 数据：`MySQL 8.0`
- 视频：`mediamtx + GStreamer`
- 实时接口：`HTTP API :8080` + `WebSocket :12345`

物理链路可以简单记成：

`雷达 + 球机 + PLC -> ARM 后端 -> HTTP/WebSocket -> 浏览器前端`

## 推荐阅读顺序

### 所有人先看
1. [`README.md`](../README.md)
   作用：主线、目录、开发/部署入口。
2. [`docs/system-architecture.md`](system-architecture.md)
   作用：系统拓扑、主数据流、页面到 API 的映射。
3. [`DOC/项目完成状态说明.md`](../DOC/项目完成状态说明.md)
   作用：当前完成度和主线范围。

### 看前端时
1. [`frontend/docs/frontend-architecture.md`](../frontend/docs/frontend-architecture.md)
2. [`DOC/前端模块结构README.md`](../DOC/前端模块结构README.md)

### 看部署和现场时
1. [`DOC/部署与运维README.md`](../DOC/部署与运维README.md)
2. [`DOC/系统操作说明书_V1.1.md`](../DOC/系统操作说明书_V1.1.md)
3. [`DOC/ARM Debian 11原生部署速查.md`](../DOC/ARM%20Debian%2011原生部署速查.md)
4. [`DOC/现场联调验收README.md`](../DOC/现场联调验收README.md)
5. [`scripts/arm/README.md`](../scripts/arm/README.md)

### 看算法和点云时
1. [`DOC/点云现场算法总览README.md`](../DOC/点云现场算法总览README.md)
2. [`DOC/点云算法设计README.md`](../DOC/点云算法设计README.md)
3. [`DOC/点云显示与融合全链路梳理.md`](../DOC/点云显示与融合全链路梳理.md)

## 仓库地图
- `backend/`：Qt 后端主线，包含配置、雷达、PLC、视频、点云处理、HTTP/WebSocket。
- `frontend/`：Vue 前端主线，配置中心在 `frontend/src/views/config/*`。
- `config/`：默认配置。
- `scripts/`：开发、构建、打包、部署、验活脚本。
- `scripts/arm/`：当前推荐的 ARM 阶段化构建、下发、验活主入口。
- `docs/`：当前主线架构、接口对齐、问题台账、superpowers 设计/计划。
- `DOC/`：说明书、协议文档、部署与现场联调文档、模块 README。

## 常用入口

### 第一轮推荐命令

如果是第一次进入这个仓库，先跑这几条最省时间：

```bash
rtk git status --short
rtk npm --prefix frontend run build
rtk npm --prefix frontend test
rtk ./scripts/frontend-dev.sh
rtk ./scripts/build-native-backend.sh backend-linux-debug
```

说明：
- `rtk npm --prefix frontend test` 是当前最稳的前端整体验证入口。
- 如果 `rtk npm --prefix frontend run build` 因 `Cannot find native binding` 或 `@rolldown/binding-linux-x64-gnu` 失败，先执行 `rtk npm --prefix frontend install` 再重跑；这是当前 Vite 8 / rolldown 可选依赖的已知恢复动作。
- 涉及首页、监控页、历史回放的真实浏览器回归，优先用 `rtk npm --prefix frontend run test:browser -- tests/browser/monitor-browser-smoke.spec.mjs --config=playwright.config.mjs`。
- 如果只跑单个前端 `node --test` 文件，优先从 `frontend/` 目录执行；很多测试按 `frontend` 作为工作目录解析相对路径。

### 开发
后端构建：

```bash
rtk ./scripts/build-native-backend.sh backend-linux-debug
```

前端开发：

```bash
rtk ./scripts/frontend-dev.sh
```

前端整体验证：

```bash
rtk npm --prefix frontend run build
rtk npm --prefix frontend test
```

前端浏览器 smoke：

```bash
rtk npm --prefix frontend run test:browser:install
rtk npm --prefix frontend run test:browser -- tests/browser/monitor-browser-smoke.spec.mjs --config=playwright.config.mjs
```

前端单测定点排查：

```bash
rtk bash -lc 'cd frontend && node --test tests/config-center-page-contract.test.mjs'
```

### 打包与部署
原生打包：

```bash
rtk ./scripts/deploy.sh backend-linux-release
```

systemd 安装：

```bash
rtk sudo ./scripts/install-systemd-services.sh /etc/systemd/system gogs /opt/gogs/runtime
```

ARM 阶段化流水线：

```bash
rtk bash scripts/arm/pipeline.sh
rtk bash scripts/arm/pipeline.sh --frontend-only
rtk bash scripts/arm/deploy_frontend.sh
rtk bash scripts/arm/verify_remote.sh
```

建议：
- 只发前端时，优先用 `scripts/arm/deploy_frontend.sh` 或 `scripts/arm/pipeline.sh --frontend-only`。
- 非必要不要再手工拼 `ssh + rsync + nginx reload` 长命令，优先走 `scripts/arm/` 固定入口。

### 验活

```bash
rtk ./scripts/verify-native-runtime.sh /opt/gogs/runtime
```

## 配置体系要点

### 真实配置来源
当前配置中心以 `GET /api/config/schema` 为单一真实字段来源。前端大多数配置页不是手写字段，而是按后端 schema 过滤后展示。

### 当前分域规则
后端当前按 key 前缀把配置分到四个域：

- 作业运维：`system/*`、`processing/*`、`recording/*`、`ui/inventory_schedules`
- 设备通信：`camera/*`、`plc/*`、`ui/plc_mappings`、`ui/scale_devices`
- 业务配置：`pile_manager/*`、`lidar_calibration/*`
- 高级维护：`tanway_sdk/*`

这意味着：
- 自动策略不是独立数据库表单心智，当前主入口实际挂在 `ui/inventory_schedules`。
- PLC 映射和称重设备列表并不只是页面状态，而是分别落在 `ui/plc_mappings`、`ui/scale_devices`。

### 关于旧 `lidar/*`
当前后端主链优先读取 `tanway_sdk/*`；只有在对应 Tanway 字段缺失时，才回落旧 `lidar/*` 兼容键。也就是说：

- `lidar/*` 仍有历史兼容意义
- 但新配置中心的主编辑入口已经不是旧 `lidar/*`

## 配置中心速记

### `/config/operations`
运行参数、自动策略、算法预设、变更记录。

### `/config/devices`
PLC、称重、视频接入、链路诊断。

### `/config/business`
物料、料堆/区域、校准、业务规则。

### `/config/advanced`
系统概览、维护动作、用户权限、专家参数。

## 雷达配置现在在哪
这是当前最容易找错的点。

### 1. 雷达接入参数
路径：`/config/advanced/expert`

这里承载的是 `tanway_sdk/*`，包括：

- `lidar_mode`
- `lidar_type`
- `on-line_config/lidar_ip`
- `on-line_config/host_ip`
- `on-line_config/data_port`
- `on-line_config/dif_port`
- `on-line_config/imu_port`
- `on-line_config/lidar_id`

这部分才是当前真实的 Tanway 雷达接入配置主入口。

### 2. 雷达标定参数
路径：`/config/business/calibration`

这里承载的是 `lidar_calibration/*`，包括：

- `offset_x/y/z`
- `roll_deg/pitch_deg/yaw_deg`
- `z_bias`

它解决的是“雷达怎么摆正、怎么进世界坐标系”，不是网络接入。

### 3. 视频接入页面
路径：`/config/devices/access`

这个页面现在叫“视频与录像接入”，实际只加载：

- `camera/*`
- `recording/*`

它不展示 `tanway_sdk/*`，职责已经收口为视频链路接入，不再误导用户去这里找雷达网络参数。

## 当前认知差异
当前仓库同时存在两套心智：

- 旧文档心智：`通信配置 -> 雷达配置`
- 新前端心智：`高级维护 -> 专家参数（tanway_sdk）` + `业务配置 -> 坐标校准`

因此“没找到雷达配置”不是使用问题，而是信息架构和命名没有完全收口。

## 当前最容易踩的坑

1. `rtk npm test` 不能替代 `rtk npm --prefix frontend test`
   前者如果在仓库根目录执行，不一定落到当前前端这套测试入口；当前稳定入口是 `--prefix frontend`。
2. 前端定点 `node --test` 不要默认在仓库根目录跑
   很多测试按 `frontend/` 为工作目录解析路径，最稳妥的写法是 `rtk bash -lc 'cd frontend && node --test ...'`。
3. 旧 `ConfigView.vue` 已经不是配置编辑主入口
   现在它只是迁移导航壳；真实配置编辑入口在 `/config/*` 新配置中心。
4. `视频与录像接入` 不等于 `雷达接入`
   `tanway_sdk/*` 现在在 `/config/advanced/expert`，不要继续按旧“通信配置 -> 雷达配置”去找。
5. ARM 发版优先走 `scripts/arm/`
   当前仓库已经有阶段化发布和远端验活脚本，手工命令应视为兜底，不应再作为主流程。

## 对后续维护最重要的结论
- 查系统主线，先看 `README + docs/system-architecture.md`
- 查前端落点，先看 `frontend/docs/frontend-architecture.md`
- 查现场部署，先看 `DOC/部署与运维README.md + scripts/arm/README.md`
- 查雷达接入，不要再优先去“视频与录像接入”页，而是先看 `/config/advanced/expert`
- 查雷达外参，不要去专家参数页找，而是去 `/config/business/calibration`
- 查前端验证，优先用 `rtk npm --prefix frontend run build` 和 `rtk npm --prefix frontend test`
- 查 ARM 发布，优先用 `rtk bash scripts/arm/pipeline.sh` 系列入口

## 风险与待定项
- 旧版说明书里仍然存在“通信配置/激光雷达配置”的叙述，和现有新配置中心不完全一致。
- 旧文档和现场习惯里，仍有人会按“通信配置/雷达配置”路径寻找新页面。
- `tanway_sdk/*` 全部下沉到“专家参数”后，普通管理员仍可能不知道这里就是雷达接入主入口。

## 下一步建议
1. 后续统一修正文档里旧的“通信配置/雷达配置”说法。
2. 把 `scripts/arm/` 的阶段化入口同步进更多主线文档，减少继续传播手工部署命令。
3. 如果设备域还要继续强化上手性，可以把“雷达接入参数”和“雷达标定”做成更显眼的任务卡。
4. 若后续权限模型允许，可评估是否把“雷达接入参数”从专家参数中再拆出单独专题页。
