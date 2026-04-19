# 视频录制与回放系统

## 架构概览

```
摄像头 (RTSP/ONVIF)
       │
       ├── RTSP Stream ──> mediamtx ──> HLS/WebRTC ──> 前端 VideoPlayer (实时)
       │
       ├── RTSP Stream ──> GStreamer (gst-launch-1.0) ──> MP4 文件 ──> 后端文件服务 ──> 前端 PlaybackView (回放)
       │
       └── ONVIF SOAP ──> VideoManager ──> PTZ 控制 / 抓图
```

## 录制

### 后端 GStreamer 录制 (VideoManager)

**入口**: `VideoManager::startRecording()` / `stopRecording()`

**两种模式**:
| 模式 | GStreamer Pipeline | 适用场景 |
|------|-------------------|---------|
| 单文件 | `rtspsrc → depay → parse → mp4mux → filesink` | 短时录制 |
| 分段 | `rtspsrc → depay → parse → splitmuxsink` | 长时连续录制 |

**配置**:
```ini
[recording]
enabled = true          # 是否启用
save_days = 30          # 保留天数
segment_duration = 3600 # 分段时长(秒), 0=单文件
input_codec = auto      # auto / h264 / h265
```

**文件存储**: `data/videos/yyyyMMdd/HHmmss.mp4`

**自动清理**: `pruneExpiredRecordings()` 按保留天数自动删除过期文件和空目录

**API 端点**:
| 端点 | 方法 | 说明 |
|------|------|------|
| `/api/video/recording/start` | POST | 开始录制 |
| `/api/video/recording/stop` | POST | 停止录制 |
| `/api/video/recording/status` | GET | 录制状态 + GStreamer 兼容性检查 |

### 前端录制 (MonitorView)

**两种录制方式**:
1. **本地录制**: 浏览器 `MediaRecorder` + `captureStream()` → WebM 下载
2. **后端录制**: 调用 `/api/video/recording/start` → GStreamer → MP4

**逻辑**: 优先本地录制，不支持时自动降级到后端录制

## 录像记录管理

### 后端索引 (JSON)

**位置**: `data/videos/video-records.json`

**每条记录字段**:
```json
{
  "id": "uuid",
  "filePath": "data/videos/20260414/143022.mp4",
  "file": "143022.mp4",
  "streamUrl": "/api/video-files/stream?path=...",
  "status": "completed | recording",
  "recordingMode": "single-file | splitmuxsink-segment",
  "segmentIndex": -1,
  "recordingAt": "2026-04-14T14:30:22",
  "createdAt": "2026-04-14T14:30:22",
  "duration": 120,
  "size": "15.2 MB"
}
```

**API 端点**:
| 端点 | 方法 | 说明 |
|------|------|------|
| `/api/video-records` | GET | 列表(支持过滤/排序) |
| `/api/video-records` | POST | 创建/更新记录 |

**GET 过滤参数**: `limit`, `startTime`, `endTime`, `keyword`, `status`, `mode`, `sortBy`

**排序**: `latest` | `oldest` | `recording-first` | `single-file-first`

### 文件服务

| 端点 | 方法 | 说明 |
|------|------|------|
| `/api/video-files/stream` | GET | 流式播放视频文件 |
| `/api/video-files/download` | GET | 下载视频文件 |

**安全**: 路径遍历防护，只允许访问 `data/videos/` 目录

## 回放 (PlaybackView)

**前端文件**: `frontend/src/views/PlaybackView.vue`

### 多轨同步回放

```
┌──────────────────────────────────────────────────────┐
│ 视频轨道   [VideoPlayer]  ←  MP4 streamUrl           │
│ 点云轨道   [Three.js]     ←  PCD 文件下载            │
│ 作业轨道   [ECharts]      ←  作业历史数据             │
├──────────────────────────────────────────────────────┤
│ 时间轴  [00:00 ●━━━━━━━━━━━━━━━━━━━━━━━━━ 24:00]    │
│         ▲ 标记: 作业事件 / 快照事件                    │
├──────────────────────────────────────────────────────┤
│ 控制: ◀ ▶ ■ │ 速度: 0.5x 1x 2x 4x │ 同步: ☑        │
└──────────────────────────────────────────────────────┘
```

### 数据源

| 轨道 | 数据 API | 说明 |
|------|---------|------|
| 视频 | `GET /api/video-records` | 按日期范围查询录像文件 |
| 点云 | `GET /inventory-snapshots` | 库存快照含点云文件路径 |
| 作业 | `GET /history/operations` | 历史作业记录 |

### 功能清单

- ✅ 三轨同步回放 (视频 + 点云 + 作业)
- ✅ 24 小时时间轴滑块 + 事件标记
- ✅ 播放/暂停/停止/跳进/跳退
- ✅ 倍速播放 (0.5x ~ 4x)
- ✅ 日期范围选择 (今天/昨天/近7天/自定义)
- ✅ 视频文件列表 (按状态/模式/关键词过滤排序)
- ✅ 点云文件列表 (PCD 加载 + Three.js 渲染)
- ✅ 作业事件时间线
- ✅ 智能分析弹窗 (作业统计/库存趋势/饼图/建议)
- ✅ 作业数据柱状图 + 折线图
- ✅ 文件下载 (视频/点云)
- ✅ 路径复制 / 摘要复制
- ✅ URL 状态持久化 (route query params)
- ✅ 高级搜索 / 关键词搜索

### 路由状态持久化

PlaybackView 通过 URL query params 保存回放状态:
```
/playback?start=2026-04-14&end=2026-04-14&time=52380&video=data/...&section=视频轨道
```

**参数**: `start`, `end`, `time`, `video`, `map`, `event`, `section`, `videoKeyword`, `videoStatus`, `videoMode`, `videoSort`, `search`

## 已知限制与改进方向

| 项目 | 当前状态 | 改进方向 |
|------|---------|---------|
| 录像自动重启 | 进程崩溃后不重启 | 可添加录制进程健康检查和自动重启 |
| 视频拖拽定位 | 流式返回整个文件 | 支持 HTTP Range 请求实现精确拖拽 |
| 录制调度 | 仅手动触发 | 可增加定时录制/事件触发录制 |
| 视频预览 | 无缩略图 | 可生成缩略图/预览片段 |
| 批量操作 | 无 | 可增加批量删除/下载 |
