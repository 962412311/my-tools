# 抓斗作业引导及盘存系统

## 系统概述

抓斗作业引导及盘存系统面向行车抓斗作业场景，完成激光雷达点云采集、PLC 位姿接入、点云融合建图、最高点检测、体积盘存、历史回放和前端可视化。

当前主线已经统一为：
- 后端：`ARM Debian 11` 原生运行的 `Qt 6.2.4 + C++17` 服务
- 前端：独立部署的 `Vue 3 + Vite` 静态页面
- 通信：`HTTP API + WebSocket`
- 数据：`MySQL 8.0` 原生服务
- 视频：`mediamtx + GStreamer` 原生服务

## 技术架构

### 后端技术栈
- 语言：C++17
- 框架：Qt 6.2.4
- 点云处理：PCL 1.11.1 + Eigen 3.3.9
- 图像/视频：GStreamer 1.18+ + mediamtx
- 可选图像能力：OpenCV 4.5.1（目标机可通过 `apt` 安装，当前后端主链不作为必需依赖）
- 工业通信：Qt SerialBus（`QModbusTcpClient` / `QModbusRtuSerialClient`）
- 数据库访问：QtSql（`QSqlDatabase` / `QSqlQuery`，使用 `QMYSQL` 驱动）
- 数据库服务：MySQL 8.0 / MariaDB 原生服务
- 雷达 SDK：Tanway LidarView 双平台接入
  - Windows：编译 `backend/SDK/LidarView/arm linux 2026123/sdk` 中的 SDK 源码 wrapper，并在运行时携带 `backend/SDK/LidarView/win v2.0.6` 运行时包
  - ARM Linux：编译 `backend/SDK/LidarView/arm linux 2026123/sdk` 原始源码
  - 接入方式：通过编译宏区分平台，保留原 SDK 文件不改动；Windows 侧不直接依赖 `win v2.0.6` 里的开发库
  - 在线模式下的 host IP 由后端自动按雷达网段探测

### 前端技术栈
- 框架：Vue 3 + Vite
- UI：Element Plus
- 3D 可视化：Three.js
- 图表：ECharts
- 视频播放：video.js

### 硬件平台
- 边缘服务器：RK3588 / ARM64
- 操作系统：Debian 11 / ARM64
- 传感器：48 线激光雷达 + 球机
- 控制侧：PLC（提供行车 `x/y` 位姿）

## 系统架构

```text
┌─────────────────┐      ┌────────────────────────────┐      ┌─────────────────┐
│  车载感知单元   │      │  ARM Debian 11 边缘服务器   │      │  远程监控终端   │
│  ┌───────────┐  │      │  ┌──────────────────────┐  │      │  ┌───────────┐  │
│  │48线雷达   │──┼──────┼─▶│ Qt 原生后端服务       │  │      │  │PC/平板/   │  │
│  └───────────┘  │      │  │ - 雷达/PLC/点云处理   │  │      │  │手机浏览器 │  │
│  ┌───────────┐  │      │  │ - HTTP/WebSocket      │◀─┼──────┼──┤           │  │
│  │400万球机  │──┼──────┼─▶│ - 历史记录/快照/回放   │  │      │  └───────────┘  │
│  └───────────┘  │      │  ├──────────────────────┤  │      │                 │
│                 │      │  │ MySQL / mediamtx      │  │      │                 │
│                 │      │  │ data/ logs/ maps/     │  │      │                 │
└─────────────────┘      └────────────┬─────────────┘  └─────────────────┘
                                      │ Modbus TCP/RTU
                                 ┌────▼────┐
                                 │ 行车 PLC │
                                 │ (X, Y)   │
                                 └──────────┘
```

## 目录结构

```text
backend/          Qt 后端源码
frontend/         Vue 前端源码
config/           默认配置文件
scripts/          原生构建与部署脚本
DOC/              设计文档、协议文档、说明书
todo.md           持续推进中的待办清单
```

重点设计补充：
- [文档索引](DOC/README.md)
- [GOGS RTK（快速上手包）](docs/gogs-rtk.md)
- [前端模块结构 README](DOC/前端模块结构README.md)
- [后端服务架构 README](DOC/后端服务架构README.md)
- [视频链路与 ONVIF README](DOC/视频链路与ONVIFREADME.md)
- [PLC 控制链路 README](DOC/PLC控制链路README.md)
- [部署与运维 README](DOC/部署与运维README.md)
- [系统操作说明书 V1.1](DOC/系统操作说明书_V1.1.md)
- [现场联调验收 README](DOC/现场联调验收README.md)
- [点云表面层轨迹融合设计说明](DOC/点云表面层轨迹融合设计说明.md)
- [项目完成状态说明](DOC/项目完成状态说明.md)

协议对接优先级：
- PLC 对接以现场最新速查表为准；当前优先参考 `DOC/PLC接口通讯协议接口速查表V1.1.docx`
- `DOC/PLC接口通讯协议_V2.0.md` 保留为完整设计说明，若与 `V1.1` 速查表冲突，以 `V1.1` 的现场寄存器和状态位定义为准

算法设计补充：
- [点云算法设计 README](DOC/点云算法设计README.md)
- [低置信度主动补扫 README](DOC/低置信度主动补扫README.md)

## 原生开发

说明：
- 在 Codex / CLI 会话里，仓库内 shell 命令统一建议加 `rtk` 前缀。
- 如果只想快速建立当前仓库上下文，先看 [GOGS RTK（快速上手包）](docs/gogs-rtk.md)。

### 后端环境要求
- Qt 6.2.4
- PCL 1.11.1
- Eigen3 3.3.9
- Qt SerialBus / Qt SerialPort
- QtSql 的 `QMYSQL` 运行时驱动（`qsqlmysql.dll`，并带上对应 MySQL / MariaDB 客户端库）
- CMake 3.16+
- 可选：OpenCV 4.5.1（仅作为目标机可用环境能力记录）

### 后端构建

ARM Debian 11：

```bash
export Qt6_DIR=/opt/Qt/6.2.4/gcc_64/lib/cmake/Qt6
sudo apt install libeigen3-dev libpcl-dev

# 若 Qt 不是系统包安装，而是单独部署，需要显式设置 Qt6_DIR
# PCL 1.11.1 和 Eigen3 3.3.9 通过 apt 安装时默认可由 CMake 自动发现
# 若使用非系统安装目录，再按需设置 PCL_DIR / Eigen3_DIR

rtk ./scripts/build-native-backend.sh backend-linux-debug
```

Tanway 雷达 SDK 说明：
- Windows 构建编译 `backend/SDK/LidarView/arm linux 2026123/sdk` 下的源码 wrapper，并在构建后复制 `backend/SDK/LidarView/win v2.0.6` 运行时包
- ARM Linux 构建直接编译 `backend/SDK/LidarView/arm linux 2026123/sdk` 下的源码并链接其 `lib` 目录下的算法库
- 不修改原始 SDK 文件；平台差异由 CMake 宏和目标源文件选择处理
- `LidarDriver` 继续作为项目内部统一业务接口，对上层点云处理、WebSocket、HTTP API 保持不变

Windows：

```bat
set Qt6_DIR=C:\Qt\6.2.4\msvc2019_64\lib\cmake\Qt6
set PCL_DIR=C:\3rdparty\PCL\cmake
set Eigen3_DIR=C:\3rdparty\eigen\share\eigen3\cmake

scripts\build-native-backend.bat backend-win-msvc-release
```

说明：
- Windows 下如果需要启用 QtSql 的 `QMYSQL` 插件，MSVC 需要链接 `C:/vcpkg/installed/x64-windows/lib/libmysql.lib`
- `scripts\build-native-backend.bat` 会自动尝试加载 Visual Studio 的 `vcvars64.bat`，不必先手工打开开发者命令行
- 构建完成后会自动拷贝 `qsqlmysql.dll`、`libmysql.dll`、`libcrypto-3-x64.dll`、`libssl-3-x64.dll` 到输出目录
- 这是 Windows 平台的运行时/链接依赖，ARM Debian 11 原生部署不需要这一条

### 后端运行

```bash
rtk ./backend/build/backend-linux-debug/GrabSystem
```

后端默认端口：
- HTTP API：`http://127.0.0.1:8080/api`
- WebSocket：`ws://127.0.0.1:12345`

说明：
- 后端启动时会自动在当前工作目录下创建 `config/config.ini`
- 配置文件首次生成时会自动补齐数据库、雷达、PLC、相机和算法默认项
- 已存在但缺失或留空的配置项也会在启动时用默认值回填并重新落盘
- 如果旧配置文件缺少数据库段，启动时会自动重建并补齐
- 数据库链路会自动完成建库、建表、补列与补索引

### 前端开发

```bash
rtk ./scripts/frontend-dev.sh
```

开发环境默认地址：
- 前端：`http://127.0.0.1:3000`
- API 代理：`http://127.0.0.1:8080`
- WebSocket 代理：`ws://127.0.0.1:12345`
- 默认管理员：`admin / Admin@123`

说明：
- 请统一通过 `scripts/frontend-dev.*`、`scripts/frontend-build.*`、`scripts/frontend-install.*` 进入前端流程。
- 这些脚本会检测当前平台；如果发现 `frontend/node_modules` 来自其他平台，会自动删除并重新安装。
- `frontend/node_modules` 仍然不能在 Windows 与 WSL/Linux 间直接复用，但现在不需要手工排查。
- 独立前端生产部署时，需要显式设置后端地址，见 [`frontend/.env.production.example`](/mnt/d/qtworkdata/gogs/frontend/.env.production.example)。
- 当前前端整体验证入口推荐统一用：

```bash
rtk npm --prefix frontend run build
rtk npm --prefix frontend test
```

- 浏览器验收 smoke 已收进仓库；首次执行前先安装 Chromium：

```bash
rtk npm --prefix frontend run test:browser:install
rtk npm --prefix frontend run test:browser -- tests/browser/monitor-browser-smoke.spec.mjs --config=playwright.config.mjs
```

- 如果只跑单个前端 `node --test` 文件，建议从 `frontend/` 目录执行，例如：

```bash
rtk bash -lc 'cd frontend && node --test tests/config-center-page-contract.test.mjs'
```

## ARM Debian 11 部署

### 推荐部署形态

- `Qt` 后端作为系统服务原生运行
- `MySQL` 原生运行
- `mediamtx` 原生运行
- 前端构建为静态文件，由 `nginx`、`caddy` 或任意静态文件服务器独立发布

### 运行目录建议

```text
runtime/
├── backend/
│   ├── bin/GrabSystem
│   ├── bin/config/config.ini
│   ├── config/mediamtx.yml
│   ├── data/videos/
│   ├── data/maps/
│   └── bin/logs/
└── frontend/
    └── dist/
```

### 一键打包原生运行目录

除了下面的原生打包脚本，当前更推荐直接使用 [`scripts/arm/README.md`](scripts/arm/README.md) 里定义的阶段化流水线入口，减少继续手工拼接 `ssh` / `rsync` / `nginx reload` 命令。

ARM Debian 11：

```bash
rtk ./scripts/deploy.sh backend-linux-release
```

Windows：

```bat
scripts\deploy.bat backend-win-msvc-release
```

脚本会：
- 检查原生构建产物
- 创建 `runtime/` 目录
- 复制后端二进制与默认配置
- 复制前端 `dist/`（如果已构建）
- 额外镜像一份前端 `dist` 到后端 `web/`，用于可选单机静态托管
- 复制 `deploy/systemd/` 模板到 `runtime/systemd/`
- 创建 `data/`、`logs/` 等运行目录

### 前端生产构建

独立前端部署时，先设置环境变量：

```bash
cd frontend
cp .env.production.example .env.production
# 按实际后端地址修改 .env.production
rtk ../scripts/frontend-build.sh
```

如果部署到测试机，当前推荐直接使用：

```bash
rtk bash scripts/arm/deploy_frontend.sh
```

如果需要完整 ARM 阶段化发布：

```bash
rtk bash scripts/arm/pipeline.sh
rtk bash scripts/arm/pipeline.sh --frontend-only
rtk bash scripts/arm/verify_remote.sh
```

### 后端启动示例

```bash
cd runtime/backend/bin
./GrabSystem
```

### 前端静态发布示例

```bash
cd runtime/frontend
python3 -m http.server 8081
```

也可以将 `runtime/frontend` 交给 `nginx` 或 `caddy` 发布。

如果希望由后端直接托管前端静态资源，也可以直接访问：
- `http://<backend-host>:8080/`

### systemd 模板

仓库已提供：
- [`deploy/systemd/grab-system.service`](/mnt/d/qtworkdata/gogs/deploy/systemd/grab-system.service)
- [`deploy/systemd/mediamtx.service`](/mnt/d/qtworkdata/gogs/deploy/systemd/mediamtx.service)
- [`deploy/systemd/README.md`](/mnt/d/qtworkdata/gogs/deploy/systemd/README.md)
- [`scripts/install-systemd-services.sh`](/mnt/d/qtworkdata/gogs/scripts/install-systemd-services.sh)

推荐启动顺序：
1. `mysql.service`
2. `mediamtx.service`
3. `grab-system.service`
4. `nginx.service` 或其他前端静态服务

目标机上可直接执行：

```bash
rtk ./scripts/verify-native-runtime.sh /opt/gogs/runtime
```

用于检查运行目录、systemd 状态、HTTP API、WebSocket 端口和前端静态资源是否完整。

如需安装 systemd 服务，也可以直接执行：

```bash
rtk sudo ./scripts/install-systemd-services.sh /etc/systemd/system gogs /opt/gogs/runtime
```

## 配置说明

### 数据库配置

编辑 [`config/config.ini`](/mnt/d/qtworkdata/gogs/config/config.ini)：

```ini
[database]
host=127.0.0.1
port=3306
username=gogs_user
password=gogs123
database=gogs
```

### 雷达配置

```ini
[lidar]
ip=192.168.111.51
port=5600
info_port=5700
```

### PLC 配置

```ini
[plc]
protocol=TCP
ip=192.168.1.100
port=502
```

### 前端生产环境配置

编辑 [`frontend/.env.production.example`](/mnt/d/qtworkdata/gogs/frontend/.env.production.example) 并改名为 `.env.production`：

```dotenv
VITE_DATA_SOURCE=backend
VITE_API_BASE_URL=http://192.168.1.20:8080/api
VITE_WS_URL=ws://192.168.1.20:12345
```

## 故障排除

1. `QMYSQL driver not loaded`
   - 这不是 MySQL 服务器配置问题，而是 Qt 运行时没有加载到 MySQL SQL 驱动插件
   - 确认 Qt 安装目录下存在 `plugins/sqldrivers/qsqlmysql.dll`
   - 先确认本项目的构建后拷贝是否成功把 `qsqlmysql.dll`、`libmysql.dll`、`libcrypto-3-x64.dll`、`libssl-3-x64.dll` 放到了可执行文件目录
   - 如果仍然缺失，再检查系统 `PATH` 或手工部署路径
   - 可先设置 `QT_DEBUG_PLUGINS=1` 查看插件加载失败原因

2. 后端找不到配置文件
   - 确认后端程序对运行目录有写权限
   - 检查 `runtime/backend/bin/config/config.ini` 是否已自动生成

3. Qt / PCL 构建失败
   - 检查 `Qt6_DIR`、`PCL_DIR`、`Eigen3_DIR`
   - 确认 Qt 安装包含 `SerialBus`、`SerialPort`、`Sql` 模块

4. 前端连接不到后端
   - 检查 `VITE_API_BASE_URL`
   - 检查 `VITE_WS_URL`
   - 检查 8080 / 12345 端口是否开放

5. 监控页视频截图失败
   - 浏览器本地截图依赖视频元素允许 `drawImage`，跨域或播放器限制下会失败
   - 当前后端已提供 `GET /api/video/snapshot` 作为抓图兜底，依赖相机 ONVIF `GetSnapshotUri`
   - 若实机仍失败，优先检查 `camera/onvif_url`、账号密码，以及设备是否要求额外的 WS-Security 鉴权

6. 视频回放没有数据
   - 检查 `runtime/backend/data/videos/`
   - 检查 `mediamtx` 与录像配置

## 项目状态

- 当前仓库内部的代码、文档、部署脚本和数据库自举逻辑已经收口完成。
- 项目唯一剩余的最终验证项是目标 `ARM Debian 11` 目标机上的原生构建与联调验收。
- 详细状态说明见 [`DOC/项目完成状态说明.md`](/mnt/d/qtworkdata/gogs/DOC/项目完成状态说明.md)。

## 维护

### 日志

```bash
tail -f runtime/backend/bin/logs/grab_system.log
```

### 数据备份

```bash
mysqldump -u root -p gogs > backup.sql
tar -czf maps_backup.tar.gz runtime/backend/data/maps
tar -czf videos_backup.tar.gz runtime/backend/data/videos
```

### 更新

```bash
git pull
./scripts/build.sh backend-linux-release
./scripts/deploy.sh backend-linux-release
```

## 许可证

MIT License
