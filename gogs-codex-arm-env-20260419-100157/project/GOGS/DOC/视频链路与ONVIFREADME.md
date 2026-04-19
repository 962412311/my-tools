# 视频链路与 ONVIF README

## 目标

这份文档用于说明当前项目的视频主线如何工作，重点回答四个问题：

1. 实时视频是怎么到前端的
2. ONVIF 云台和预置位由谁负责
3. 抓图和录像在前后端如何分工
4. 后续继续完善时，代码应该改哪里

补充约束：

- 当前项目的视频实现目标是固定配置、固定环境的 ARM Linux 主机稳定运行
- 不以泛化兼容各种主机、版本和插件组合作为当前设计目标
- 若后续实机验证暴露真实问题，再针对现场问题修复

## 当前视频链路概览

当前视频链路分成三层：

1. 相机与流媒体层
2. 后端视频控制层
3. 前端播放与交互层

```text
Camera (RTSP / ONVIF)
        |
        +-> mediamtx / HLS / RTSP
        |         |
        |         +-> Frontend Video Player
        |
        +-> ONVIF Device / Media / PTZ Service
                  |
                  +-> VideoManager
                  +-> HttpServer /api/video/*
                  +-> Frontend MonitorView
```

## 实时回放主线

### 流媒体来源

当前实时回放主线默认依赖：

- 相机 RTSP 地址
- `mediamtx + GStreamer`
- 前端播放器组件

当前优先级约束：

- 监控页实时显示默认优先使用 `WebRTC/WHEP`
- `HLS` 作为浏览器兼容性和链路异常时的降级路径
- 若现场通过环境变量覆盖视频地址，也应保持 `VITE_WEBRTC_URL` 优先、`VITE_HLS_URL` 降级
- 监控页顶部会直接显示当前实际命中的实时链路，并在 `WebRTC -> HLS` 降级或环境变量强制 `HLS` 时给出显式提示
- `/api/video/stream-info` 返回的链路异常原因会直接显示在监控页顶部，便于快速发现 `mediamtx` 配置未同步、端口不可达等问题
- 监控页顶部会直接显示 `MediaMTX` 健康状态，区分 `健康 / 配置待同步 / 未配置 RTSP / 异常`
- 监控页顶部会直接显示 `API / HLS / WebRTC` 三类端口探测结果，便于区分是 `9997` API、`8888` HLS 还是 `8889` WebRTC 端口未通
- 监控页顶部会直接显示 `配置源` 是否已同步到当前 `streamPath`，用于识别 `camera source` 未写入或未同步
- 监控页顶部会常驻显示当前录像输入编码配置，现场无需进入配置页也能确认 `自动` / `H.264` / `H.265`
- 监控页顶部会直接显示当前录像前提是否就绪，以及 `gst-launch` / `gst-inspect` 缺失导致的阻塞状态
- 监控页顶部会直接显示“录像健康”，区分 `录像中 / 健康 / 降级 / 异常`
- 监控页顶部会直接显示关键录像插件可用数量，现场可快速判断当前机子是否满足录制主线前提
- 如果关键插件缺失，监控页顶部会直接显示缺失插件名，现场无需额外展开接口返回体
- 配置页的 `recording/input_codec` 会直接给出海康 H.265 机型建议和 WebRTC 浏览器兼容性提示，减少现场误配
- 当前项目级浏览器兼容建议已整理到 [`DOC/视频浏览器兼容矩阵.md`](/mnt/d/QtWorkData/GOGS/DOC/视频浏览器兼容矩阵.md)
- `V1.1` 视频链路版本化验收出口已整理到 [`DOC/V1.1视频链路版本化验收清单.md`](/mnt/d/QtWorkData/GOGS/DOC/V1.1视频链路版本化验收清单.md)
- 海康 `RTSP / ONVIF / ISAPI / SDK` 的职责边界已整理到 [`DOC/海康SDK与ISAPI能力边界.md`](/mnt/d/QtWorkData/GOGS/DOC/海康SDK与ISAPI能力边界.md)
- 海康现场接入与排障顺序已整理到 [`DOC/海康设备联调SOP.md`](/mnt/d/QtWorkData/GOGS/DOC/海康设备联调SOP.md)
- 配置页运行参数顶部会直接显示“海康视频配置基线”，固定当前推荐口径：
  - 主码流用于录像
  - 子码流用于实时预览
  - 主码流默认按 `2K / 15fps~25fps`
  - 子码流建议 `720p / 15fps`
  - 编码按浏览器兼容性在 `H.264 / H.265` 之间确认
- 后端运行参数 schema 现已补齐 `camera/main_stream_*` 和 `camera/sub_stream_*` 结构化字段，用于固化这套现场基线
- 监控页顶部会直接显示“视频基线”，把当前主/子码流分辨率、帧率和编码摘要带到现场联调界面
- 监控页头部现已提供“复制视频摘要”动作，可把当前实时链路、链路异常、`MediaMTX`、端口探测、配置源、视频基线、浏览器兼容、视频自检、录像前提、录像健康、保留策略、插件和录像编码整理成一段文本，便于直接贴到现场记录模板
- 监控页顶部现已直接显示“自检项”，把 `/api/video/self-check` 的 `stream / recording / ptz / snapshot` 四类拆分结果汇总成一行，现场不用只看总的“通过 / 待确认 / 阻塞”

建议的现场判断顺序：

1. 先看监控页顶部“实时链路”
2. 再看“链路异常”
3. 再看“MediaMTX”
4. 再看“端口探测 / 配置源”
5. 再看“录像前提”
6. 再看“录像健康 / 录像异常”
7. 再看“插件 / 缺失插件”
8. 最后看“录像编码”

这样可以先排除流媒体链路和运行环境问题，再进入编码兼容性与具体动作验证。

当前约束：

- 当前这些字段用于固化海康视频联调基线和监控页摘要，还不会直接替代设备真实码流配置
- 如果后续要做现场强校验、自动验收或自动下发设备配置，需要再补设备配置映射和验收脚本

后端 `VideoManager` 会持有：

- `rtspUrl`
- `onvifUrl`
- `username`
- `password`

但它目前不直接承担浏览器视频解码。浏览器播放链路仍然以流媒体分发为主。

### 历史录像回放

当前历史录像由后端扫描 `data/videos/` 目录后暴露给前端：

- `GET /api/video-records`
- `POST /api/video-records`
- `GET /api/video-files/stream?path=...`

`GET /api/video-records` 当前支持按 `startTime` / `endTime` / `keyword` / `status` / `mode` / `sortBy` 过滤和排序，前端回放页会把当前录像列表条件直接传给后端。`sortBy=recording-first` 按录制状态优先，`sortBy=single-file-first` 按单文件优先。

职责划分：

- 后端负责列目录、过滤时间、做路径白名单、Range 响应，以及为单文件录像保存轻量索引
- 前端负责把返回的 `streamUrl` 喂给播放器

这个设计的优点是简单、可控，但也意味着：

- 录像元数据当前仍以文件系统为主，但单文件录像已能写入轻量索引，回放页可以展示更完整的会话语义和完成状态
- 时长目前仍以文件/会话元数据为主，不做视频流真实探测

## ONVIF 控制链路

### 后端落点

核心类：

- `backend/include/drivers/video/VideoManager.h`
- `backend/src/drivers/video/VideoManager.cpp`

当前已经接上的 ONVIF 能力：

- `ContinuousMove`
- `RelativeMove`
- `Stop`
- `GotoHomePosition`
- `GetPresets`
- `GotoPreset`
- `SetPreset`
- `GetSnapshotUri`

`VideoManager` 当前做的事：

1. 用 `GetCapabilities` 获取 Media/PTZ 服务地址
2. 用 `GetProfiles` 获取 `ProfileToken`
3. 发送 SOAP 请求到 ONVIF 服务
4. 统一返回 `lastError`

这意味着：

- ONVIF 设备细节尽量留在 `VideoManager`
- `HttpServer` 只做 API 转发和错误透传

### HTTP 接口层

核心路由在：

- `backend/src/service/HttpServer.cpp`

当前已暴露：

- `GET /api/video/ptz/status`
- `GET /api/video/ptz/presets`
- `POST /api/video/ptz/presets/goto`
- `POST /api/video/ptz/presets`
- `POST /api/video/ptz/move`
- `POST /api/video/ptz/relative-move`
- `POST /api/video/ptz/stop`
- `POST /api/video/ptz/home`
- `GET /api/video/snapshot`

当前接口策略：

- 优先透传后端真实错误
- 不在前端硬编码假成功
- `GET /api/video/ptz/status` 返回配置态、最近错误、最近动作和动作时间，用于前端显示云台是否可控并便于真机联调排障
- 监控页也会直接显示 `RTSP`、`ONVIF` 和账号三项配置完成度，便于现场快速判断云台联调阻塞点
- 监控页还会显示 `WS-Security` 是否启用，便于确认海康类设备是否走到了 UsernameToken 安全头链路

### ONVIF 地址推导规则

现场如果只确认了 `RTSP` 地址，而 `ONVIF` 设备服务地址还不明确，当前后端会按下面的顺序自动尝试：

1. 配置中显式填写的 `camera/onvif_url`
2. 从 `RTSP` 主机推导出的 `http://<camera-host>/onvif/device_service`
3. 从 `RTSP` 主机推导出的 `http://<camera-host>/onvif`

一旦某个入口成功返回 `GetCapabilities`，后端会把它视为当前有效的设备服务入口，并继续解析 Media/PTZ 服务地址与 `ProfileToken`。

这意味着：

- `camera/onvif_url` 可以留空，不再强依赖人工猜测
- 如果配置里残留了旧测试 IP，而 `RTSP` 已经切到新相机主机，后端也会优先尝试与 `RTSP` 同主机的 ONVIF 入口
- 对于海康这类常见球机，`/onvif/device_service` 会被优先尝试

## 抓图分工

### 前端优先路径

实时监控页在：

- `frontend/src/views/MonitorView.vue`

当前抓图策略是：

1. 如果当前布局是视频布局，优先对浏览器中的 `video` 元素做 `drawImage`
2. 如果本地截图失败，自动回退到后端 `GET /api/video/snapshot`
3. 如果当前布局是点云或货场，则直接导出对应 `canvas`

这样做的原因：

- 浏览器本地截图成本最低
- 但视频源可能受跨域、编码或播放器实现限制，不能假设始终成功

### 后端兜底路径

后端抓图接口：

- `GET /api/video/snapshot`

实际流程：

1. `VideoManager` 调 ONVIF `GetSnapshotUri`
2. 解析相机返回的快照地址
3. 后端带鉴权去抓取图片
4. 把图片二进制返回给前端

适用场景：

- 浏览器本地 `drawImage` 失败
- 视频源不可直接截图
- 需要统一由后端带相机鉴权

当前限制：

- 依赖相机暴露可用的 `SnapshotUri`
- 若相机不返回可用的 `SnapshotUri`，仍需按现场型号确认厂商特有抓图方式

## 录像分工

### 前端当前能力

当前监控页录像优先走浏览器本地能力：

- `MediaRecorder`
- `video.captureStream()`

优势：

- 不依赖后端转码
- 开发成本低

限制：

- 不是所有浏览器都支持
- 不是所有视频源都支持 `captureStream`
- 导出格式和稳定性受浏览器实现影响

所以当前代码里已经明确留有 `TODO`：

- 当浏览器本地录像不可用时，优先回退到后端 `GStreamer` 录像

### 后端当前状态

`VideoManager` 已有：

- `configureRecording(...)`
- `startRecording(...)`
- `stopRecording()`
- `isRecording()`

录像保存天数也已经参与实际清理：

- `recordingSaveDays` 会在录像启动前扫描 `data/videos/`
- 超过保留天数的历史 MP4 会自动删除
- 目录命名仍沿用 `data/videos/yyyyMMdd/HHmmss.mp4`，便于按日期收口和清理

录像分段时长也已经真正接入：

- `recordingSegmentDuration > 0` 时会驱动 `splitmuxsink` 的 `max-size-time`
- `recordingSegmentDuration = 0` 时回退到 `mp4mux` 单文件直存主线
- 分段文件使用 `HHmmss-%05d.mp4` 命名，便于按日期目录清理和回放
- 这意味着后端录像不再只是“能录”，还可以按固定时长切片，方便长时保存和现场排障

当前后端录像兜底已经接成 `GStreamer-first` 主线：

- `GET /api/video/recording/status`
- `POST /api/video/recording/start`
- `POST /api/video/recording/stop`
- `GET /api/video/self-check`

`GET /api/video/recording/status` 现在会顺带暴露 `gst-launch-1.0` 和 `gst-inspect-1.0` 是否可执行，方便在 ARM 目标机上快速判断录像链路是否具备基础运行前提。
监控页顶部现在也会直接显示 `MediaMTX` 健康、端口探测、配置源同步、录像前提、录像健康、关键插件可用数量以及 `gst-launch` / `gst-inspect` 是否缺失，便于现场一眼判断是否能继续录像联调。
它还会返回 `rtspsrc`、`h264parse`、`mp4mux`、`splitmuxsink` 和 `qtmux` 的插件检查结果，便于现场直接定位缺失的 GStreamer 组件。
它也会返回 `healthStatus`、`healthMessage`、`checkedAt`、`recoveryStatus`、`restartAttempts`、`lastRestartAt`、`retentionDays`、`lastPrunedCount` 和 `lastPrunedAt`，用于区分“工具/插件未齐”“当前录像进行中”“录像进程异常”“自动恢复过程”以及“最近一次过期清理结果”。
`GET /api/video/self-check` 会进一步把 `stream / recording / ptz / snapshot` 四类状态汇总成 `overallStatus / summaryMessage / checkItems`，用于页面和脚本统一读取视频链路自检结论。

当前自动恢复策略：

1. 后端录像进程异常退出后，会进入限次自动恢复
2. 默认最多自动尝试 `3` 次
3. 自动恢复过程中，监控页顶部“录像健康”会进入 `恢复中`
4. 自动恢复成功后，状态会回到 `健康`
5. 自动恢复失败后，状态会进入 `异常`

当前实现方式：

1. `VideoManager` 使用 `QProcess` 启动 `gst-launch-1.0`
2. 默认把文件落到 `data/videos/yyyyMMdd/HHmmss.mp4`，分段模式则追加 `-%05d`
3. 单文件录像停止后由后端返回 `outputPath + streamUrl`，分段录像停止后仅返回输出目录信息
4. 前端监控页在本地 `MediaRecorder` 不可用或启动失败时，自动回退到后端录像
5. ONVIF 请求会自动附加 `WS-Security UsernameToken`，用于兼容要求 SOAP 安全头的海康设备
6. 后端录像输入编码可在 `recording/input_codec` 中选择 `自动`、`H.264` 或 `H.265`，监控页会常驻显示当前编码
7. `recordingSaveDays` 会在每次启动录像前触发一次过期清理，最近清理数量和时间会通过录像状态接口暴露给前端

`todo.md` 中对应未完成项：

- ARM Linux 主机上的 `GStreamer` 版本、插件和录像 API 实测验证

## 前后端职责边界

### 后端负责

- 相机 ONVIF 能力接入
- PTZ 与预置位 API
- 抓图兜底
- `GStreamer` 后端录像兜底
- 历史录像目录枚举与文件流转发
- 视频错误统一透传

### 前端负责

- 视频组件展示
- 监控页视频交互
- 本地截图优先路径
- 本地录像优先路径
- 后端兜底接口调用

### 不应该混淆的边界

- 不要把 ONVIF SOAP 细节放到前端
- 不要把浏览器 `MediaRecorder` 逻辑塞到后端
- 不要在前端伪造 PTZ 成功状态

## 当前主要限制

1. 后端录像主线已闭环，但 ARM 现场机上的 `GStreamer` 版本、插件和管线兼容性仍需实测
2. ONVIF PTZ 仍需真实摄像头联调，重点核对方向、速度、停止和预置位语义
3. SnapshotUri 依赖具体设备兼容性，个别机型仍需现场确认抓图返回格式和鉴权行为
4. 历史录像时长当前不是精确探测值

## 摄像头支持结论

当前仓库内与摄像头直接相关的软件能力已经收口到可现场验收状态：

- 标准 `ONVIF Device / Media / PTZ` 已接入
- `WS-Security UsernameToken Digest` 已可自动附加到 ONVIF SOAP 请求
- `GetSnapshotUri` 后端抓图兜底已接入
- `RTSP` 实时预览与后端 `GStreamer` 录像兜底已接入
- 录像输入编码支持 `自动`、`H.264`、`H.265`
- 监控页和现场验收脚本都能直接看到 PTZ、录像和安全头状态

## 后续开发建议

1. 若继续强化后端录像，优先仍放在 `VideoManager`，不要直接塞进 `HttpServer`
2. 若要适配更多厂商的安全头变体，继续扩展 `sendOnvifRequest(...)`
3. 若要补录像元数据管理，可单独引入录像索引层，不要继续依赖目录扫描承担全部语义
4. 前端监控页继续只做页面行为，不承担协议和相机适配

## 代码入口

- `backend/src/drivers/video/VideoManager.cpp`
- `backend/src/service/HttpServer.cpp`
- `frontend/src/services/api.js`
- `frontend/src/views/MonitorView.vue`
