# ARM Debian 11 原生部署速查

这是一份面向现场执行的简版步骤，默认目标机为 ARM Debian 11。

补充约定：

- 当前仓库脚本默认在仓库根目录 `/userdata/GOGS` 执行
- 在 Codex / CLI 会话里，命令统一建议加 `rtk` 前缀
- 测试机前端发布优先用 `rtk bash scripts/arm/deploy_frontend.sh`

## 1. 先装系统包

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
  git \
  chromium
```

## 2. 安装 Node.js 20

```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
node -v
npm -v
```

## 3. 构建前端

```bash
cd /userdata/GOGS/frontend
npm install
npm run build
```

如果要走仓库统一脚本，推荐这样执行：

```bash
cd /userdata/GOGS
rtk ./scripts/frontend-install.sh
rtk ./scripts/frontend-build.sh
```

验收点：

- `frontend/dist/index.html` 存在
- `frontend/dist/assets/` 存在

## 4. 构建后端

```bash
cd /userdata/GOGS
rtk ./scripts/build-native-backend.sh backend-linux-release
```

如果要连前端一起构建：

```bash
cd /userdata/GOGS
rtk ./scripts/build.sh backend-linux-release
```

## 5. 打包运行目录

```bash
cd /userdata/GOGS
rtk ./scripts/deploy.sh backend-linux-release
```

生成后重点确认：

- `/userdata/GOGS/backend/GrabSystem`
- `/userdata/GOGS/backend/config/config.ini`
- `/userdata/GOGS/backend/web/`
- `/userdata/GOGS/frontend/dist/`

## 6. 启动

### 后端

```bash
cd /userdata/GOGS/backend
./start.sh
```

常见端口：

- HTTP: `8080`
- WebSocket: `12345`

### 前端静态页

```bash
cd /userdata/GOGS/frontend/dist
python3 -m http.server 8081
```

## 7. 验证

```bash
cd /userdata/GOGS
rtk ./scripts/verify-native-runtime.sh /userdata/GOGS
rtk ./scripts/verify-arm-deployment.sh /userdata/GOGS
```

如果是当前固定的编译机/测试机流程，需要从工作站对“已部署完成的测试机”做远端验收，优先直接执行：

```bash
rtk bash scripts/arm/generate_field_acceptance_report.sh
```

补充说明：

- 测试机的真实运行根是 `/userdata/GOGS`
- 后端手工启动优先用 `/userdata/GOGS/backend/start.sh`
- 不要再按旧版 `runtime/backend/bin` 的路径去找启动入口

## 8. 常见问题

- `nodejs` 太旧：不要只用 Debian 11 默认源，改装 NodeSource 20
- `QMYSQL driver not loaded`: 检查 Qt MySQL 驱动和客户端库
- `8080` 被占用: 检查旧进程
- `12345` 被占用: 检查 WebSocket 旧进程
