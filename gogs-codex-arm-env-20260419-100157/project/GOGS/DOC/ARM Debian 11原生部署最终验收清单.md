# ARM Debian 11 原生部署最终验收清单

## 1. 环境准备

补充约定：

- 当前仓库脚本默认按仓库根目录执行，建议先 `cd /userdata/GOGS`
- 在 Codex / CLI 会话里，命令统一建议加 `rtk` 前缀
- 测试机前端发布或远端验活优先使用 `scripts/arm/` 阶段化入口

### 1.1 安装 Qt 运行与开发组件

至少包含以下模块：
- Core
- Network
- WebSockets
- Sql
- SerialBus
- SerialPort

### 1.2 安装第三方依赖

- PCL 1.11.1
- Eigen3 3.3.9
- MySQL 或 MariaDB 服务
- Qt 的 `QMYSQL` 驱动（以及对应的 MySQL / MariaDB 客户端库）
- GStreamer
- mediamtx
- 可选：OpenCV 4.5.1

## 2. 环境变量

```bash
export Qt6_DIR=/opt/Qt/6.2.4/gcc_64/lib/cmake/Qt6
sudo apt install libeigen3-dev libpcl-dev
```

验收点：
- `Qt6_DIR` 指向可用的 Qt6 CMake 目录
- `PCL 1.11.1` 与 `Eigen3 3.3.9` 已通过 Debian 11 `apt` 安装
- 若使用系统包安装，默认无需额外设置 `PCL_DIR` / `Eigen3_DIR`

## 3. 后端构建

```bash
cd /userdata/GOGS
rtk ./scripts/build-native-backend.sh backend-linux-release
```

验收点：
- `cmake` 配置成功
- `cmake --build` 成功
- 生成 `backend/build/backend-linux-release/GrabSystem`

## 4. 前端构建

```bash
cd /userdata/GOGS/frontend
rm -rf node_modules
npm install
npm run build
cd /userdata/GOGS
```

验收点：
- 生成 `frontend/dist`

## 5. 打包原生运行目录

```bash
cd /userdata/GOGS
rtk ./scripts/deploy.sh backend-linux-release
```

验收点：
- 生成并同步到 `/userdata/GOGS`
- 后端二进制、配置文件、前端静态文件、systemd 模板都已复制到位

## 6. 配置文件检查

编辑并确认：
- `/userdata/GOGS/backend/config/config.ini`

重点检查配置段：
- `database`
- `lidar`
- `plc`
- `camera`
- `processing`

验收点：
- 数据库地址、账号、库名正确
- 雷达 IP/端口正确
- PLC 通信参数正确
- 相机 RTSP 地址正确
- 点云处理参数符合现场要求

## 7. 基础服务准备

启动并确认：
- MySQL 或 MariaDB
- mediamtx

验收点：
- 数据库可连接
- mediamtx 正常监听配置端口

## 8. 启动后端

```bash
cd /userdata/GOGS/backend
./start.sh
```

验收点：
- 进程启动成功
- HTTP 监听 `8080`
- WebSocket 监听 `12345`
- 日志目录正常写入

## 9. 启动前端静态服务

示例：

```bash
cd /userdata/GOGS/frontend/dist
python3 -m http.server 8081
```

也可以使用 `nginx` 或 `caddy`。

验收点：
- 浏览器能正常访问前端页面

## 10. 原生运行体检

```bash
cd /userdata/GOGS
rtk ./scripts/verify-native-runtime.sh /userdata/GOGS
```

如果运行目录不同，替换为实际路径。

验收点：
- 目录结构检查通过
- systemd 服务检查通过
- HTTP API 检查通过
- WebSocket 端口检查通过
- 前端静态资源检查通过

如果要一次性串联原生运行体检和现场联调验收，也可以直接执行：

```bash
cd /userdata/GOGS
rtk ./scripts/verify-arm-deployment.sh /userdata/GOGS
```

如果当前环境已经部署完成，只需要从工作站做当前 ARM 远端健康检查并导出证据报告，优先执行：

```bash
rtk bash scripts/arm/generate_field_acceptance_report.sh
```

如果只想看最小远端健康摘要，则执行：

```bash
rtk bash scripts/arm/verify_remote.sh
```

本地脚本会生成 `native-runtime-report.md`、`field-acceptance-report.md` 和 `arm-deployment-report.md`；当前远端脚本会在 `logs/arm/` 下生成新的 markdown 证据报告，建议一并归档。

## 11. 前后端联调

验证以下页面与接口：
- 登录页
- 首页概览
- 监控页
- 远程操作页
- 盘存页
- 回放页
- 配置页
- 用户管理页

验收点：
- 登录正常
- 页面无接口报错
- WebSocket 正常接收实时状态
- 配置读写正常

## 12. PLC 联调

重点检查：
- PLC 连接状态
- `/api/control/status`
- `/api/control/statistics`
- `/api/control/*` 指令下发
- 位姿读取

验收点：
- PLC 状态可读
- 远程控制接口可用
- 位姿数据能进入后端

## 13. 雷达联调

重点检查：
- `DIF` 接收
- `PCF` 接收
- 点云入处理线程
- `processingDiagnostics` 更新
- 地图更新
- 最高点更新

验收点：
- 雷达点云可稳定进入处理链
- 点云过滤、融合、地图更新正常
- 最高点检测结果可见

## 14. 盘存与回放联调

重点检查：
- 生成库存快照
- 导出 `PCD`
- 点云文件可下载
- 回放时间轴正常
- 历史事件正常
- 视频回放正常

验收点：
- 库存快照、回放、点云文件链路完整

## 15. ONVIF PTZ 联调

重点检查：
- `/api/video/ptz/move`
- `/api/video/ptz/relative-move`
- `/api/video/ptz/stop`
- `/api/video/ptz/home`
- `/api/video/ptz/presets`
- `/api/video/ptz/presets/goto`

建议动作顺序：
1. 拉取预置位列表，确认读写均可用
2. 先做小幅 `move`，验证方向和速度映射
3. 做一次 `relative-move`，确认相机相对位移正确
4. 立即 `stop`，确认能停住且不会漂移
5. `home` 回零，确认默认位姿回归
6. `goto preset`，确认预置位跳转一致

验收点：
- 球机接受当前 SOAP + HTTP Auth 方案
- 方向与速度映射正确
- 预置位读写兼容
- 若设备要求 WS-Security，当前实现已可自动附加 UsernameToken Digest 安全头，并在监控页显示启用状态

## 16. 视频抓图与录像联调

重点检查：
- 浏览器本地截图失败时是否回退后端抓图
- 浏览器 `captureStream` 不可用时是否回退后端录像
- `GET /api/video/snapshot`
- `GET /api/video/recording/status`
- `POST /api/video/recording/start`
- `POST /api/video/recording/stop`

建议核查命令：

```bash
gst-launch-1.0 --version
gst-inspect-1.0 rtspsrc
gst-inspect-1.0 h264parse
gst-inspect-1.0 mp4mux
gst-inspect-1.0 splitmuxsink
gst-inspect-1.0 qtmux
```

验收点：
- 目标机 `GStreamer` 版本可记录
- 关键插件齐全
- 录像管线能启动并正常结束
- 分段录像模式能按 `recordingSegmentDuration` 正常切片
- 录像输入编码可按现场选择 `recording/input_codec`，默认自动探测，海康默认 H.265 机型也可手动切到 H.265
- 单文件录像停止后可拿到有效 `streamUrl` 并下载
- 分段录像停止后不自动下载，但可在录像记录页查看分段文件
- 录制文件可播放

## 17. 真实料堆慢速扫描联调

重点检查：
- `processing/blind_zone_annulus_thickness_factor`
- `processing/blind_zone_height_quantile`
- `volumeBlindZoneCoverageRatio`
- `volumeBlindZoneDensityRatio`
- `volumeBlindZoneSupportRatio`
- `volumeBlindZoneCompensation`

建议记录项：
- 料型
- 扫描速度
- 当前 `Z`
- 环厚参数
- 分位数参数
- `volumeBlindZoneCoverageRatio`
- `volumeBlindZoneDensityRatio`
- 体积曲线稳定性

验收点：
- 参数变化对补偿结果的趋势符合预期
- 体积曲线平滑，不虚高
- 中心盲区不会长期空洞

## 18. 最终验收结论

当以下条件全部满足时，可判定项目完成：
- 后端原生构建通过
- 前端构建通过
- 前后端联调通过
- PLC 联调通过
- 雷达联调通过
- 盘存与回放联调通过
- ONVIF PTZ 联调通过
- 视频抓图与录像联调通过
- 真实料堆慢速扫描联调通过

完成后，将 [`todo.md`](/mnt/d/QtWorkData/GOGS/todo.md) 中最后一项勾掉：

- `在目标 ARM Debian 11 目标机完成一次完整构建与联调验收（WSL 不执行）`

## 19. 当前状态说明

截至当前仓库状态：
- 代码主线已完成
- 文档、依赖、历史遗留已完成清理
- 仓库已收口为 ARM Debian 11 原生部署主线
- 仍需在目标机完成原生构建、现场联调和实机验收闭环

## 20. 现场验收脚本

本地 runtime 目录自查时建议同步使用：

```bash
./scripts/verify-field-acceptance.sh /opt/gogs/runtime
```

当前固定 ARM 流程下，如需远端现场总验收，优先改用：

```bash
rtk bash scripts/arm/verify_field_acceptance_bundle.sh
```

当前脚本会额外核查：

- 原生运行目录基础检查
- `GStreamer` 工具和关键插件
- `/api/video/recording/status` 的 `gst-launch` / `gst-inspect` 可用性
- `/api/video/recording/status` 的 `allChecksCompleted` 和关键插件逐项可用性
- `/api/video/ptz/status` 的最近动作留痕
- `/api/scales/status` 的称重运行态连通性

作用：

- 给现场联调留下可复核的统一报告
- 作为 ARM 目标机验收的快速巡检入口
