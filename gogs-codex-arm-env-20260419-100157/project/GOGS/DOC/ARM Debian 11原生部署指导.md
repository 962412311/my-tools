# ARM Debian 11 原生部署指导

本文档面向 ARM Debian 11 目标机，用于说明如何安装运行前端所需环境、构建前端静态资源，并与后端原生运行目录配合完成部署。

补充说明：

- 当前测试机 / ARM 发布主流程优先参考 [GOGS RTK（快速上手包）](../docs/gogs-rtk.md) 与 [`scripts/arm/README.md`](../scripts/arm/README.md)
- 在 Codex / CLI 会话里，命令统一建议加 `rtk` 前缀
- 仓库脚本默认按仓库根目录执行，即 `/userdata/GOGS`，不要在 `/userdata/GOGS/backend` 下直接运行 `./scripts/...`

适用场景：

- 目标机系统为 Debian 11
- CPU 架构为 ARM64 / aarch64
- 前端以 Vite 构建为静态站点
- 后端以 Qt 6 原生程序托管静态资源或由独立静态服务发布

不适用场景：

- 仅在 Windows 开发机本地调试
## 1. 前端部署目标

仓库中的前端是独立的 Vue 3 + Vite 应用，构建产物为 `frontend/dist`。  
后端会优先从运行目录下的 `web` 或 `frontend/dist` 读取静态资源。

前端构建入口：

```bash
cd frontend
npm install
npm run build
```

仓库也提供了统一脚本：

```bash
rtk ./scripts/frontend-install.sh
rtk ./scripts/frontend-build.sh
```

## 2. Debian 11 需要安装的系统包

建议先安装基础工具和编译依赖：

```bash
sudo apt update
sudo apt install -y \
  ca-certificates \
  curl \
  gnupg \
  build-essential \
  python3 \
  make \
  g++ \
  pkg-config \
  git
```

如果目标机还要直接打开前端页面进行验证，可额外安装浏览器：

```bash
sudo apt install -y chromium
```

说明：

- `build-essential`、`python3`、`make`、`g++` 用于安装和编译部分 Node 原生依赖
- `curl`、`gnupg` 用于添加 NodeSource 软件源
- `chromium` 仅用于浏览器访问，不是前端构建必需

## 3. 安装 Node.js 20

这个前端使用 Vite 5，建议安装 Node.js 20 LTS，避免 Debian 11 自带旧版本 Node 导致构建失败。

安装命令：

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
```

验证版本：

```bash
node -v
npm -v
```

推荐结果：

- `node` 版本为 `v20.x`
- `npm` 可正常执行

## 4. 获取代码

如果代码已经在目标机上，可以直接进入仓库目录。

示例：

```bash
cd /userdata/GOGS/backend
```

如果你从 Git 仓库拉取代码，建议保持前后端目录结构完整：

```text
/userdata/GOGS/
├── backend/
├── frontend/
├── scripts/
├── config/
└── DOC/
```

## 5. 构建前端

### 5.1 方式一：直接构建

```bash
cd /userdata/GOGS/frontend
npm install
npm run build
```

### 5.2 方式二：使用仓库脚本

```bash
cd /userdata/GOGS
rtk ./scripts/frontend-install.sh
rtk ./scripts/frontend-build.sh
```

构建完成后应生成：

```text
frontend/dist/
```

验收点：

- `frontend/dist/index.html` 存在
- `frontend/dist/assets/` 存在

## 6. 构建后端

如果需要在 ARM Debian 11 上进行原生构建，使用仓库提供的后端构建脚本：

```bash
cd /userdata/GOGS
rtk ./scripts/build-native-backend.sh backend-linux-release
```

如果你要一次性构建后端和前端，可使用总构建脚本：

```bash
cd /userdata/GOGS
rtk ./scripts/build.sh backend-linux-release
```

说明：

- `build.sh` 会先构建原生后端
- 如果检测到 `npm`，还会自动构建前端
- 如果只想先把后端编出来，也可以单独执行后端构建脚本

## 7. 打包原生运行目录

构建完成后，使用部署脚本生成运行目录：

```bash
cd /userdata/GOGS
rtk ./scripts/deploy.sh backend-linux-release
```

如果目标是测试机前端发布，当前更推荐直接使用：

```bash
cd /userdata/GOGS
rtk bash scripts/arm/deploy_frontend.sh
```

如果目标是完整阶段化发布：

```bash
cd /userdata/GOGS
rtk bash scripts/arm/pipeline.sh
rtk bash scripts/arm/verify_remote.sh
```

部署脚本会生成类似以下目录结构：

```text
runtime/
├── backend/
│   ├── bin/GrabSystem
│   ├── bin/config/config.ini
│   ├── config/mediamtx.yml
│   ├── data/
│   └── web/
└── frontend/
    └── dist/
```

关键点：

- `/userdata/GOGS/backend/web` 和 `/userdata/GOGS/frontend/dist` 都会放入前端静态资源
- 后端启动时会优先寻找 `web` 或 `frontend/dist`

## 8. 配置文件检查

部署后重点检查：

```bash
/userdata/GOGS/backend/config/config.ini
```

常见需要确认的项：

- `database`
- `lidar`
- `plc`
- `camera`
- `processing`

如果目标机已经有 MySQL 或 MariaDB，请确保数据库地址、账号、密码、库名正确。

## 9. 启动方式

### 9.1 后端启动

```bash
cd /userdata/GOGS/backend
./start.sh
```

启动后常见监听端口：

- HTTP：`8080`
- WebSocket：`12345`

### 9.2 前端静态服务

如果不通过后端直接托管前端，可以单独启动静态服务：

```bash
cd /userdata/GOGS/frontend/dist
python3 -m http.server 8081
```

也可以换成 `nginx` 或 `caddy`。

## 10. 运行验证

建议在部署后检查以下项目：

```bash
cd /userdata/GOGS
rtk ./scripts/verify-native-runtime.sh /userdata/GOGS
rtk ./scripts/verify-arm-deployment.sh /userdata/GOGS
```

如果运行目录不在 `/userdata/GOGS`，请替换为实际路径。

如果当前目标是“从工作站对已经部署完成的测试机做远端验证并生成证据报告”，优先执行：

```bash
rtk bash scripts/arm/generate_field_acceptance_report.sh
```

验证重点：

- 后端二进制是否存在
- 配置文件是否存在
- 前端静态资源是否存在
- HTTP API 是否可达
- WebSocket 是否监听
- MySQL 是否可连通
- `mediamtx` 是否可用

## 11. 常见问题

### 11.1 `nodejs` 版本太旧

症状：

- `npm run build` 报错
- Vite 依赖安装失败

处理：

- 不要只用 Debian 11 默认仓库的 `nodejs`
- 改用 NodeSource 的 `Node.js 20`

### 11.2 `QMYSQL driver not loaded`

症状：

- 后端日志提示 `QMYSQL driver not loaded`
- 数据库连接失败

处理：

- 确认 Qt 的 MySQL 驱动已安装
- 确认 MySQL / MariaDB 客户端库可用

### 11.3 端口被占用

症状：

- `8080` 无法启动
- WebSocket 无法启动

处理：

- 检查是否已有旧进程残留
- 使用 `ss -ltnp` 或 `lsof -i :8080` 排查

## 12. 推荐执行顺序

建议按以下顺序操作：

1. 安装系统包
2. 安装 Node.js 20
3. 构建前端
4. 构建后端
5. 执行 `deploy.sh`
6. 检查 `config.ini`
7. 启动数据库和视频服务
8. 启动后端
9. 启动前端静态服务
10. 执行验证脚本
