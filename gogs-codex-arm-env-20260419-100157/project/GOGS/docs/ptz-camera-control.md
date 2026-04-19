# PTZ 云台控制架构与运维

## 概览

系统通过 ONVIF 协议控制海康通用 PTZ 摄像头，支持方向控制、变焦、预置位管理和抓图。
视频流通过 RTSP 接入，经 mediamtx 转码为 HLS/WebRTC 供前端播放。

## 架构

```
前端 (Vue 3)                     后端 (C++/Qt)                    摄像头 (海康)
┌──────────────┐   HTTP/REST    ┌──────────────────┐   ONVIF/SOAP   ┌──────────┐
│ PtzControls  │ ──────────────>│   HttpServer     │ ─────────────> │ PTZ 摄像头│
│ MonitorView  │                │   VideoManager   │                │ RTSP/ONVIF│
│ VideoPlayer  │ <──────────────│   ConfigManager  │ <───────────── │          │
│ api.js       │   JSON/JSON    │                  │   SOAP/XML     └──────────┘
└──────────────┘                └──────────────────┘
                                        │
                                   GStreamer
                                   (录像进程)
```

## 关键组件

### 后端 VideoManager (`backend/src/drivers/video/VideoManager.cpp`)

- **ONVIF 连接管理**: 通过 WSSE 认证与摄像头通信
- **PTZ 控制**: 方向(pan/tilt)、变焦(zoom)、预置位、复位
- **录像管理**: GStreamer 分段/单文件录像
- **健康探测**: 30s 间隔定期检查摄像头在线状态
- **自动重连**: 检测到离线后自动清除 ONVIF 缓存，恢复后重新发现

### 前端 PtzControls (`frontend/src/components/monitor/PtzControls.vue`)

- 方向控制面板 (上下左右 + 中心复位)
- 变焦滑块 (1-20x)
- 预置位选择器与保存
- 连接状态指示 (已就绪/待联机/离线/未配置)

### 前端 MonitorView (`frontend/src/views/MonitorView.vue`)

- 30s 定期刷新 PTZ 状态
- 视频重连成功后自动刷新 PTZ 状态
- 离线时禁止 PTZ 操作，显示等待重连提示

## API 端点

| 端点 | 方法 | 说明 |
|------|------|------|
| `/api/video/ptz/status` | GET | PTZ 状态 (含 onvifConnected 字段) |
| `/api/video/ptz/presets` | GET | 预置位列表 |
| `/api/video/ptz/presets` | POST | 保存预置位 |
| `/api/video/ptz/presets/goto` | POST | 跳转预置位 |
| `/api/video/ptz/move` | POST | 持续移动 (ContinuousMove) |
| `/api/video/ptz/relative-move` | POST | 相对移动 (RelativeMove) |
| `/api/video/ptz/stop` | POST | 停止移动 |
| `/api/video/ptz/home` | POST | 回到原点 |
| `/api/video/snapshot` | GET | 抓图 |
| `/api/video/stream-info` | GET | 视频流信息 |

## 自动重连机制

### ONVIF 链路维护

1. **定期健康探测** (30s): `VideoManager::performHealthCheck()` 发送 GetCapabilities 探测摄像头
2. **失败计数**: 连续失败 >= 2 次后清除 ONVIF 缓存 (service URLs + profile token)
3. **自动重发现**: 缓存清除后下次 PTZ 操作自动触发 `ensureOnvifReady()` 重新发现
4. **状态通知**: 通过 `onvifStateChanged(bool)` 信号通知前端连接状态变化

### PTZ 命令失败处理

- 每个 PTZ 命令失败后递增 `m_consecutiveFailures`
- 连续失败 >= 2 次后清除 ONVIF 缓存
- 成功的命令重置失败计数并更新连接状态为已连接

### 视频流重连

- VideoPlayer 使用指数退避重连 (1s → 15s, 最多 8 次)
- 前端在 visibilitychange 和 online 事件触发视频流恢复
- 视频重连成功后自动刷新 PTZ 状态

## 配置

```ini
[camera]
rtsp_url = rtsp://admin:password@192.168.x.x/stream
onvif_url = http://192.168.x.x/onvif
username = admin
password = password

[recording]
enabled = true
save_days = 30
segment_duration = 3600
input_codec = auto
```

### 海康摄像头 ONVIF 注意事项

- ONVIF 默认端口通常为 80，URL 格式: `http://<IP>/onvif`
- 需要在摄像头 Web 管理界面启用 ONVIF 服务
- WSSE 认证使用 Digest 模式 (自动处理)
- 部分型号需要在安全设置中单独开启 ONVIF 用户

## 状态流转

```
未配置 (missing_config)
  ↓ 配置 RTSP/ONVIF/用户名
已配置 + 离线 (offline)
  ↓ ONVIF 健康探测成功
已配置 + 在线 (configured)
  ↓ PTZ 操作成功
已就绪 (ready)
  ↓ PTZ 操作失败
已配置 + 在线 (configured)  或  离线 (offline)
```
