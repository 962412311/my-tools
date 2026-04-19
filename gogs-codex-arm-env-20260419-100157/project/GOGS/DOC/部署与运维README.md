# 部署与运维 README

## 目标

这份文档用于统一说明当前项目的部署形态、运行目录、开发机构建方式、目标机运维入口，以及 systemd/mediamtx/MySQL 的协作关系。

它是运维视角文档，不重复算法和业务说明。

补充约束：

- 当前部署主线只面向固定配置的 ARM Linux 目标机
- 优先保证现场固定环境稳定运行，不以广泛兼容不同主机环境为当前目标

统一入口约定：

- 如果是新会话或回归维护，先看 [GOGS RTK（快速上手包）](../docs/gogs-rtk.md)
- 在 Codex / CLI 会话里，命令统一建议加 `rtk` 前缀
- 测试机和 ARM 发布优先走 `scripts/arm/` 阶段化入口，不再把手工 `ssh + rsync + nginx reload` 作为主流程

## 当前推荐部署形态

当前项目已经统一到这条主线：

- 后端：`Qt 6.2.4 + C++17` 原生服务
- 目标机：`ARM Debian 11 / ARM64`
- 前端：独立构建后的静态站点
- 数据库：`MySQL 8.0 / MariaDB`
- 视频服务：`mediamtx + GStreamer`

## 环境分工

### Windows 开发机

主要用途：

- 本地开发
- MSVC 构建验证
- 运行前端开发环境
- 生成 Windows 侧 runtime 目录

关键入口：

- `scripts/build-native-backend.bat`
- `scripts/deploy.bat`
- `scripts/frontend-dev.bat`
- `scripts/frontend-build.bat`

### ARM Debian 11 目标机

主要用途：

- 正式运行后端
- 正式运行 MySQL / mediamtx
- 托管前端静态资源或对接 nginx/caddy

关键入口：

- `scripts/build-native-backend.sh`
- `scripts/deploy.sh`
- `scripts/install-systemd-services.sh`
- `scripts/verify-native-runtime.sh`
- `scripts/arm/pipeline.sh`
- `scripts/arm/deploy_frontend.sh`
- `scripts/arm/verify_remote.sh`

现场执行建议优先看：

- [ARM Debian 11 原生部署速查](ARM%20Debian%2011原生部署速查.md)
- [ARM Debian 11 原生部署指导](ARM%20Debian%2011原生部署指导.md)

## 运行目录

当前部署脚本约定的运行目录结构：

```text
runtime/
├── backend/
│   ├── bin/
│   │   ├── GrabSystem
│   │   ├── config/config.ini
│   │   └── logs/
│   ├── config/mediamtx.yml
│   ├── data/
│   │   ├── videos/
│   │   ├── maps/
│   │   ├── hls/
│   │   └── mysql/
│   └── web/
└── frontend/
    └── dist/
```

关键约束：

- 后端运行目录和配置文件路径是固定约定的一部分
- 前端 `dist` 会同时镜像到 `runtime/frontend/dist` 和 `backend/web`
- `backend/web` 用于可选的后端静态托管

## 构建与打包入口

### ARM Debian 11

后端构建：

```bash
rtk ./scripts/build-native-backend.sh backend-linux-release
```

打包运行目录：

```bash
rtk ./scripts/deploy.sh backend-linux-release
```

测试机 / ARM 阶段化发布：

```bash
rtk bash scripts/arm/pipeline.sh
rtk bash scripts/arm/pipeline.sh --frontend-only
rtk bash scripts/arm/deploy_frontend.sh
rtk bash scripts/arm/verify_remote.sh
```

建议：

- 只发前端时，优先用 `deploy_frontend.sh` 或 `pipeline.sh --frontend-only`
- 需要完整下发、重启和远端验活时，再走完整 `pipeline.sh`

### Windows

后端构建：

```bat
scripts\build-native-backend.bat backend-win-msvc-release
```

打包运行目录：

```bat
scripts\deploy.bat backend-win-msvc-release
```

## 运行时依赖

### 后端

必需：

- Qt 6.2.4 运行时
- PCL / Eigen 相关运行环境
- `config/config.ini`
- `config/mediamtx.yml`

### 数据库

当前默认：

- `MySQL 8.0` 或兼容 `MariaDB`

后端启动时会做：

- 建库
- 建表
- 补列
- 补索引

这意味着：

- 目标机上数据库服务必须先可用
- 但不要求人工预建完整表结构

### 视频

当前推荐：

- `mediamtx`
- 配合 `GStreamer`

视频链路和 ONVIF 细节已拆到：

- [视频链路与 ONVIF README](视频链路与ONVIFREADME.md)

### 测试机后端运行依赖实测清单

以下内容不是泛化建议，而是 2026-04-10 在当前测试机上按实际运行状态核出的依赖清单。目标是保证 `/userdata/GOGS/backend/GrabSystem` 能正常启动、连库、提供 HTTP / WebSocket，并具备当前录像链路所需的基础工具。

补充一个已经核实的现场事实：

- 测试机本身已经有完整的 Qt 运行环境，不要再按“缺 Qt runtime”去补环境
- 后端一键启动脚本是 `/userdata/GOGS/backend/start.sh`
- 该脚本会把 `LD_LIBRARY_PATH` 指向 `/opt/qt6.2.4-aarch64/lib`，然后直接 `exec ./GrabSystem`
- 现场手工启动和验证时，优先使用 `/userdata/GOGS/backend/start.sh`，不要临时发明新的启动路径

#### 必装系统包

当前测试机已确认安装并实际被后端依赖的包：

- `nginx`
- `mariadb-server`
- `mariadb-client`
- `libmariadb3`
- `libssl1.1`
- `libpcl-dev`
- `libopenni0`
- `libopenni2-0`
- `libpcap0.8`
- `libusb-1.0-0`
- `gstreamer1.0-tools`
- `gstreamer1.0-plugins-base`
- `gstreamer1.0-plugins-good`
- `gstreamer1.0-plugins-bad`

建议直接执行：

```bash
sudo apt update
sudo apt install -y \
  nginx \
  mariadb-server \
  mariadb-client \
  libmariadb3 \
  libssl1.1 \
  libpcl-dev \
  libopenni0 \
  libopenni2-0 \
  libpcap0.8 \
  libusb-1.0-0 \
  gstreamer1.0-tools \
  gstreamer1.0-plugins-base \
  gstreamer1.0-plugins-good \
  gstreamer1.0-plugins-bad
```

#### 非 apt 固定前提

当前后端二进制通过 `ldd` 实测依赖以下 Qt 运行时目录，测试机使用的是固定安装路径，不是 Debian 仓库自带 Qt：

- `/opt/qt6.2.4-aarch64/lib`
- `/opt/qt6.2.4-aarch64/plugins/sqldrivers`

至少需要存在这些 Qt 组件：

- `libQt6Core.so.6`
- `libQt6Network.so.6`
- `libQt6Sql.so.6`
- `libQt6WebSockets.so.6`
- `libQt6SerialBus.so.6`
- `libQt6SerialPort.so.6`
- `plugins/sqldrivers/libqsqlmysql.so`

如果测试机还没准备这套 Qt 目录，需要先把现场固定的 `Qt 6.2.4 aarch64` 运行时同步到 `/opt/qt6.2.4-aarch64`，否则后端虽然存在也无法正常启动。

#### 运行服务要求

当前测试机实测正常运行时，至少有这些 systemd 服务：

- `gogs-backend.service`
- `nginx.service`
- `mariadb.service`

建议执行：

```bash
sudo systemctl enable mariadb nginx gogs-backend.service
sudo systemctl start mariadb nginx gogs-backend.service
```

#### 快速验证命令

安装完成后，先用这些命令确认环境前提：

```bash
nginx -v
mysql --version
gst-launch-1.0 --version
ldd /userdata/GOGS/backend/GrabSystem
systemctl is-active mariadb nginx gogs-backend.service
ss -ltnp | egrep ':8080|:12345'
```

验收口径：

- `nginx`、`mysql`、`gst-launch-1.0` 都能直接执行
- `ldd /userdata/GOGS/backend/GrabSystem` 不能出现 `not found`
- `mariadb`、`nginx`、`gogs-backend.service` 均为 `active`
- 后端监听 `8080`
- WebSocket 监听 `12345`

#### 雷达联调补充

当前现场雷达实测仍向 `192.168.0.204` 发送 `5600/5900` UDP，测试机 `eth1` 需要同时保留：

- `192.168.0.17/24`
- `192.168.0.204/24`

如果只保留 `.17`，SDK 和后端会把它误判成“没有收到雷达流”。
当前后端新二进制已按 `.204` 优先绑定，并把 Tensor48 在线分帧参数恢复到 SDK 证明可用的默认范围，日志里会打印：

- `Tanway SDK initializing: lidar=192.168.0.51 host=192.168.0.204 ...`
- `PointCloudCallback` 相关帧闭合日志

现场验证时优先看这条日志，再配合 `tcpdump` 确认雷达 UDP 是否到达 `192.168.0.204:5600/5700/5900`。

补充一个稳定性约束：

- `backend/config/config.ini` 里的 `system/allowed_origins` 仍然是运行时配置，但测试机上的 `/ws` 实际经过 nginx 代理到后端 `12345`，后端默认只接受 `http://localhost:5173`、`http://localhost:3000`、`http://localhost:8080`、`http://127.0.0.1:5173`、`http://127.0.0.1:3000`、`http://127.0.0.1:8080` 这类本机 origin；当前更稳的做法是优先在 nginx `/ws` 代理里重写 `Origin`，不要反复手改 `config.ini`
- `backend/config/config.ini` 里的 `[security] jwt_secret` 可以保留占位符，后端首次启动会自动生成并写回；但运行目录里的配置文件不能被部署脚本反复覆盖，否则重启后 token 会失效，WS 会继续显示未连接
- 当前后端的认证实现会同时检查 JWT 签名、过期时间和 token cache；如果浏览器里保存的 token 在后端重启后突然全部失效，先查 `AuthManager::validateToken()` / `refreshToken()` 是否把 cache miss 当成硬失败，而不要先怀疑前端 shell
- 前端监控页的 WebSocket 连接依赖登录态 token；如果浏览器里看到 `WebSocket 未连接`，先确认已经重新登录并且前端已部署到最新构建，再看后端日志是否出现 `invalid token` 或 `Origin not allowed`
- 浏览器保持登录的场景下，如果前端一直无法自动连上 websocket，先看 `userInfo.exp` 是否跟随 token 刷新一起更新；若只刷新了 `token` 没刷新 `userInfo.exp`，路由守卫和系统状态会误判成“未登录”，表现为必须退出 admin 再重新登录
- 如果自动保持登录后 websocket 仍旧不连，新版前端会先用 `refreshToken` 做一次静默 auth recovery，再让 token watcher 触发重连；排查时重点看 `[ws] attempting auth recovery before websocket reconnect` 和 `[ws] auth recovery succeeded; websocket will reconnect on token change`
- 生产构建默认会通过 Vite/esbuild 去掉 `console.*`，所以部署版前端控制台日志不一定可见；现场联调优先看后端日志、nginx access/error log 和接口响应码

当前仓库的 `scripts/deploy.sh` 已改为“首次部署才拷贝配置模板，已存在的运行时 `config.ini` 不再覆盖”，这样自动生成的 JWT 密钥可以长期保留。

### 测试机 ROS2 / `lidar_view` 运行与构建依赖实测清单

这一节记录的是 2026-04-10 在测试机上为了跑通雷达售后提供的 ROS2 路线、编译厂家 `lidar_view` 包、并最终验证 `Tensor48` 点云链路时，已经实测确认过的依赖和命令。这里不再按“原生 SDK 就够了”去猜，后续雷达联调一律以这条链路为准。

#### 已确认存在的工具前提

- `python3`
- `g++`
- `cmake`
- `rosdep`
- `/usr/local/bin/colcon`

#### 已确认安装过的系统包

```bash
sudo apt update
sudo apt-get install -y python3-pip python3-rosdep2 python3-vcstools python3-pytest-cov python3-argcomplete build-essential git cmake curl locales
sudo apt-get install -y python3-empy python3-numpy libasio-dev libtinyxml2-dev libyaml-cpp-dev libcurl4-openssl-dev libspdlog-dev
sudo apt-get install -y libbenchmark-dev uncrustify
sudo apt-get install -y python3-lark
sudo apt-get install -y liblog4cxx-dev
sudo apt-get install -y libfastrtps-dev libfastcdr-dev
sudo apt-get remove -y libspdlog-dev libfmt-dev
```

#### 为什么要单独记录这些包

- `python3-rosdep2` / `python3-vcstools` / `python3-pip` 是 ROS2 underlay 拉依赖和补源码包时的基础工具
- `python3-empy`、`python3-lark` 解决了测试机上 `rosidl` / `launch` 链路的 Python 依赖
- `libfastrtps-dev` / `libfastcdr-dev` 是 ROS2 Galactic 对应 DDS 基础库
- `libbenchmark-dev`、`uncrustify`、`liblog4cxx-dev` 是 underlay 里部分包的编译依赖
- `libspdlog-dev` 和 `libfmt-dev` 在这台测试机上曾与 ROS2 vendor 版本冲突，已按实测移除，后续优先使用 underlay/vendor 版本

#### 典型 underlay 构建命令

```bash
env -i PATH=/usr/local/sbin:/usr/sbin:/usr/bin:/sbin:/bin HOME=/root TERM=dumb bash -lc '
cd /root/ros2_galactic &&
/usr/local/bin/colcon build --symlink-install --merge-install \
  --packages-select ament_cmake_auto class_loader composition_interfaces console_bridge_vendor eigen3_cmake_module orocos_kdl pcl_ros python_qt_binding qt_gui rclcpp_action rclcpp_components rqt_gui rqt_gui_py tango_icons_vendor tf2 tf2_geometry_msgs tf2_msgs tf2_py tf2_ros tf2_ros_py lidar_view \
  --packages-skip-build-finished \
  --event-handlers console_direct+ \
  --cmake-args -DPYTHON_EXECUTABLE=/usr/bin/python3 -DPython_EXECUTABLE=/usr/bin/python3 -DPython3_EXECUTABLE=/usr/bin/python3
'
```

#### 雷达现场诊断工具

这两个工具不是后端运行主依赖，但在当前雷达排障里已经被证明必需，建议现场机保留：

```bash
sudo apt-get install -y tcpdump arping
```

#### 现场验收口径

- `lidar_view` / `Lidar_MainNode` 能在测试机上启动
- `Tensor48` 相关配置能按 `192.168.0.17 -> 192.168.0.51:5600/5700/5900` 起链
- 后端或 demo 日志不再长期停留在 `select time out; accepted point/dif/imu=0/0/0`
- 抓包能看到来自雷达的 UDP 点云 / DIF 流量进入测试机接收口
- 一旦现场实际点云进入接收链路，再把最终运行命令和缺失依赖回写到本节

#### 本次实测结果

- `lidar_view` 已在测试机上通过 `colcon build --packages-select lidar_view` 成功编译并安装
- 直接执行 `/root/ros2_galactic/install/lib/lidar_view/Lidar_MainNode` 可正常读取现场参数
- 当 `gogs-backend.service` 占用 `5600/5700` 时，`Lidar_MainNode` 会报端口绑定失败并退出，这是端口冲突，不是源码编译错误
- 停掉 `gogs-backend.service` 后，`Lidar_MainNode` 可以正常绑定并进入 `select time out; accepted point/dif/imu=0/0/0` 状态，说明节点本身可运行，但测试机当前仍未收到雷达 UDP 点云/DIF 数据
- 当前测试机上未安装 `ros2` CLI，验证时使用的是工作区安装后的可执行文件直接启动
- 2026-04-10 复测 `SDK Demo_UseSDK.cpp` 对应的 `run_demo`，同样配置 `192.168.0.51 -> 192.168.0.17:5600/5700/5900` 和 `LT_Tensor48`，结果仍然是 `select time out; accepted point/dif/imu=0/0/0`，没有任何点云回调输出
- 这说明当前问题不在项目后端封装层，也不在 ROS2 `lidar_view` 节点层，而是在现场雷达出流 / 交换网络 / 目标 IP 路径这一层

## systemd 主线

相关文件：

- `deploy/systemd/grab-system.service`
- `deploy/systemd/mediamtx.service`
- `deploy/systemd/README.md`
- `scripts/install-systemd-services.sh`

推荐启动顺序：

1. `mysql.service`
2. `mediamtx.service`
3. `grab-system.service`
4. `nginx.service` 或其他静态文件服务

原因：

- `GrabSystem` 依赖数据库
- 视频相关能力依赖 `mediamtx`
- 前端静态站点在后端和视频链稳定后再开放更稳

### 安装模板

可直接用：

```bash
rtk sudo ./scripts/install-systemd-services.sh /etc/systemd/system gogs /opt/gogs/runtime
```

脚本会：

- 替换运行用户
- 替换安装根目录
- 安装 `grab-system.service`
- 安装 `mediamtx.service`
- 自动 `daemon-reload`
- 自动 `enable`

## 运行时验证

目标机可直接执行：

```bash
rtk ./scripts/verify-native-runtime.sh ./runtime
```

它会检查：

- 后端二进制是否存在
- 配置文件是否存在
- mediamtx 配置是否存在
- 日志和数据目录是否存在
- 前端静态资源是否存在
- `systemd` 是否启用并运行
- `HTTP API` 是否可达
- `WebSocket` 端口是否监听
- `MySQL` 是否可连通

当前 ARM 现场验收时，旧的本地 `runtime` 体检脚本只适用于“机器本地目录自查”。对于当前固定的编译机/测试机流程，优先补跑：

```bash
rtk bash scripts/arm/verify_browser_matrix_readiness.sh
rtk bash scripts/arm/verify_field_acceptance_bundle.sh
```

如果想把这两步整理成一份 markdown 证据文件，直接用：

```bash
rtk bash scripts/arm/generate_field_acceptance_report.sh
```

本地部署目录场景下，仍可补跑：

```bash
rtk ./scripts/verify-field-acceptance.sh ./runtime
```

如果想一次性跑完原生运行检查和现场联调检查，也可以直接用：

```bash
rtk ./scripts/verify-arm-deployment.sh ./runtime
```

如果当前目标是“测试机已经部署好的环境做远端健康检查”，优先直接执行：

```bash
rtk bash scripts/arm/verify_remote.sh
```

脚本会同时生成 `native-runtime-report.md`、`field-acceptance-report.md` 和 `arm-deployment-report.md`，方便现场一次性保留原生体检、现场验收和总汇总。

它会额外核查：

- `/api/video/self-check` 的 `overallStatus / summaryMessage / checkItems`
- `GStreamer` 工具和关键插件
- `/api/video/recording/status` 的 `gst-launch` / `gst-inspect` 可用性
- `/api/video/recording/status` 的 `allChecksCompleted` 和关键插件逐项可用性
- `/api/video/ptz/status` 的最近动作留痕
- `/api/scales/status` 的称重运行态连通性
- 前端监控页会同步显示录像前提是否就绪和关键插件可用数量，便于现场快速定位 GStreamer 前提问题
- 前端监控页会同步显示 `RTSP`、`ONVIF` 和账号三项 PTZ 配置完成度，便于现场快速定位云台联调阻塞点

## 运维边界

当前建议把职责分开：

- 部署脚本负责准备 runtime 目录
- systemd 负责守护和启动顺序
- 后端自身负责配置回填、建库建表和运行时业务逻辑

## 系统维护接口

新配置中心 `/config/advanced/maintenance` 里的系统维护按钮已经接到后端管理接口，前端只负责确认与展示结果，实际动作由后端执行。

- `GET /api/system/maintenance/status`
  - 返回 `mysqldump` / `systemctl` 可用性、runtime 根目录和称重驱动接入状态，称重驱动状态直接读取 `ScaleManager`
- `POST /api/system/maintenance/backup`
  - 备份当前配置快照
  - `mysqldump` 可用时会顺带导出数据库
- `POST /api/system/maintenance/cache/clear`
  - 清理后端临时缓存目录
- `POST /api/system/maintenance/restart`
  - 通过 `systemd` 的 `Restart=always` 语义安排后端重启
- `GET /api/scales/status`
  - 返回称重驱动边界、设备数量、在线采集数量和当前配置列表，由后端 `ScaleManager` 承接
- `POST /api/scales/devices`
  - 保存称重设备配置，`ScaleManager` 会按配置主动轮询 Modbus 串口/网口设备，实时读数仍可通过该接口兜底上报
  - 设备配置支持 `registerArea`、`valueType`、`wordOrder` 和 `pollIntervalMs`，用于适配现场不同称重仪表的寄存器布局和采样周期

这些接口默认仅超级管理员可调用。

不建议继续把这些职责混在一起：

- 不要让后端二进制同时承担完整部署脚本职责
- 不要让前端构建过程耦合数据库初始化
- 不要把 systemd 模板里的路径写死到代码里

## 当前限制

1. ARM 目标机仍需要一次完整联调验收
2. Windows runtime 更偏开发验证，不是最终生产部署方案
3. 后端录像已切到 `GStreamer-first` 主线，`/api/video/recording/status` 会返回 `gst-launch`、`gst-inspect` 和关键插件检查结果，但仍需在 ARM Linux 主机实测可用性
4. 视频和控制链路的现场联调仍依赖真实设备

## 后续建议

1. 若继续拆文档，可补一个“前端模块结构 README”
2. 若继续强化部署，可补目标机巡检脚本和备份恢复流程
3. 若继续强化运维，可补日志轮转、磁盘占用和录像清理策略说明

## 代码与脚本入口

- `scripts/build-native-backend.sh`
- `scripts/build-native-backend.bat`
- `scripts/deploy.sh`
- `scripts/deploy.bat`
- `scripts/install-systemd-services.sh`
- `scripts/verify-native-runtime.sh`
- `scripts/verify-field-acceptance.sh`
- `scripts/verify-arm-deployment.sh`
- `scripts/arm/README.md`
- `scripts/arm/pipeline.sh`
- `scripts/arm/deploy_frontend.sh`
- `scripts/arm/verify_browser_matrix_readiness.sh`
- `scripts/arm/verify_field_acceptance_bundle.sh`
- `scripts/arm/generate_field_acceptance_report.sh`
- `scripts/arm/verify_remote.sh`
- `deploy/systemd/README.md`
- `DOC/现场联调验收记录模板.md`
