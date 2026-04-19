# 现场联调验收 README

这份文档只面向固定配置的 `ARM Linux` 目标机，不讨论泛化兼容。

目标：

- 把必须在真实设备上验证的链路集中列出来
- 明确每一项应该看哪个页面、哪个接口、哪个诊断字段
- 让后续联调问题能快速定位到算法、视频、PLC 还是前端展示层

## 适用范围

- 目标机：固定配置 `ARM Debian 11`
- 后端：`Qt 6.2.4 + C++17`
- 前端：`Vue 3 + Vite`
- 视频：`mediamtx + GStreamer`
- 控制：现场 PLC + 真实球机 + 真实雷达

## 联调原则

- 只按现场固定环境验收，不为假设兼容场景额外扩展
- 一条链路先确认“能稳定跑通”，再处理体验和边角
- 发现不能当场闭环的问题：
  - 代码里补 `TODO`
  - 同步回写 `todo.md`
  - 必要时补到对应模块 README

建议配合使用：

- [`DOC/点云现场算法总览README.md`](/mnt/d/qtworkdata/gogs/DOC/点云现场算法总览README.md)
- [`scripts/verify-field-acceptance.sh`](/mnt/d/qtworkdata/gogs/scripts/verify-field-acceptance.sh)
- [`scripts/arm/verify_field_acceptance_bundle.sh`](/mnt/d/qtworkdata/gogs/scripts/arm/verify_field_acceptance_bundle.sh)
- [`scripts/arm/verify_browser_matrix_readiness.sh`](/mnt/d/qtworkdata/gogs/scripts/arm/verify_browser_matrix_readiness.sh)
- [`scripts/arm/generate_field_acceptance_report.sh`](/mnt/d/qtworkdata/gogs/scripts/arm/generate_field_acceptance_report.sh)
- [`scripts/arm/generate_remaining_acceptance_workpack.sh`](/mnt/d/qtworkdata/gogs/scripts/arm/generate_remaining_acceptance_workpack.sh)
- [`scripts/arm/ensure_current_acceptance_packet.sh`](/mnt/d/qtworkdata/gogs/scripts/arm/ensure_current_acceptance_packet.sh)
- [`scripts/arm/verify_remaining_acceptance_closure.sh`](/mnt/d/qtworkdata/gogs/scripts/arm/verify_remaining_acceptance_closure.sh)
- [`scripts/arm/finalize_remaining_acceptance_closure.sh`](/mnt/d/qtworkdata/gogs/scripts/arm/finalize_remaining_acceptance_closure.sh)
- [`DOC/当前现场验收包/README.md`](/mnt/d/qtworkdata/gogs/DOC/当前现场验收包/README.md)
- [`DOC/现场验收归档/README.md`](/mnt/d/qtworkdata/gogs/DOC/现场验收归档/README.md)
- [`scripts/arm/verify_scale_protocol.sh`](/mnt/d/qtworkdata/gogs/scripts/arm/verify_scale_protocol.sh)
- [`scripts/arm/verify_blind_zone_workflow.sh`](/mnt/d/qtworkdata/gogs/scripts/arm/verify_blind_zone_workflow.sh)
- [`DOC/现场联调验收记录模板.md`](/mnt/d/qtworkdata/gogs/DOC/现场联调验收记录模板.md)
- [`DOC/视频实机验收矩阵模板.md`](/mnt/d/qtworkdata/gogs/DOC/视频实机验收矩阵模板.md)
- [`DOC/称重设备现场协议核对SOP.md`](/mnt/d/qtworkdata/gogs/DOC/称重设备现场协议核对SOP.md)
- [`DOC/点云盲区补偿慢速扫描验收标准.md`](/mnt/d/qtworkdata/gogs/DOC/点云盲区补偿慢速扫描验收标准.md)

当前固定 ARM 现场流程优先使用 `scripts/arm/verify_field_acceptance_bundle.sh`、`scripts/arm/verify_browser_matrix_readiness.sh`、`scripts/arm/generate_remaining_acceptance_workpack.sh`、`scripts/arm/ensure_current_acceptance_packet.sh`、`scripts/arm/verify_remaining_acceptance_closure.sh` 和 `scripts/arm/finalize_remaining_acceptance_closure.sh`；`scripts/verify-field-acceptance.sh` 只保留给本地 `runtime` 目录自查。

旧本地脚本 `scripts/verify-field-acceptance.sh` 当前会重点核查：

- 原生运行目录基础检查
- `/api/video/self-check` 的 `overallStatus / summaryMessage / checkItems`
- `GStreamer` 工具和关键插件
- `/api/video/recording/status` 的 `gst-launch` / `gst-inspect` 可用性
- `/api/video/recording/status` 的 `allChecksCompleted` 和关键插件逐项可用性
- `/api/video/recording/status` 的当前输入编码值
- `/api/video/ptz/status` 的配置完成度字段
- `/api/video/ptz/status` 的最近动作留痕
- `/api/video/ptz/status` 的 `wsSecurityEnabled`
- `/api/video/snapshot` 的抓图兜底可用性
- `/api/scales/status` 的称重运行态连通性

## 验收顺序

建议按下面顺序进行，避免问题互相干扰：

1. PLC 位姿与远控状态
2. 雷达点云与最高点坐标
3. 环形可视域与盲区补偿
4. 视频实时流、抓图、录像
5. ONVIF PTZ 与预置位
6. 前端监控页和远程操作页观测项

## 算法排障顺序

如果问题落在点云算法链路，优先按这个顺序看：

1. `highestPointValid` 和 `highestPointCandidateCount`
2. `trajectoryFlushReason`、`trajectoryWindowFrames`、`trajectoryWindowDistance`
3. `volumeSource`、`volumeBlindZoneSupportRatio`、`volumeBlindZoneCompensation`
4. `rescanSuggested`、`rescanSuggestedReason`、`blockedReason`

原则：

- 最高点先看有效性，再看候选点
- 体积先看来源，再看补偿
- 补扫先看建议原因，再看阻塞原因
- 轨迹先看切块原因，再看窗口帧数和距离

## PLC 与位姿链路

目标：

- 确认 `PlcData::isValid()` 收紧后不会误杀现场合法位姿
- 确认无效位姿会被统计，但不会把系统拖入错误控制状态

重点接口：

- `GET /api/control/statistics`
- `GET /api/control/status`

重点页面：

- `RemoteOperationView`
- `MonitorView`

重点字段：

- `invalidPoseFrames`
- `invalidPoseConsecutiveFrames`
- `invalidPoseAlertActive`
- `invalidPoseAlertThresholdFrames`
- `invalidPoseAlertCount`
- `lastInvalidPoseTime`
- `lastInvalidPoseAlertTime`
- 当前 `gantryPose.x/y/z/theta`
- 当前模式、作业阶段、控制会话状态

通过标准：

- 正常运行时位姿持续更新
- `invalidPoseFrames` 不持续异常增长
- `invalidPoseConsecutiveFrames` 在脏值恢复后能及时归零
- `invalidPoseAlertActive` 只在持续无效达到阈值后拉起，恢复有效位姿后自动清除
- `invalidPoseAlertCount` 只在持续失真触发时递增，不应在连续无效期间反复抖动
- `lastInvalidPoseTime` 只在异常时刷新，便于区分偶发和持续失真
- `lastInvalidPoseAlertTime` 只在持续失真首次触发时刷新，便于定位真正的告警起点
- PLC 冷启动或瞬时异常时，不会把错误位姿写入控制链路

## 最高点与坐标系链路

目标：

- 确认 `buildPoseTransform(pose)` 后的绝对/相对坐标方向正确
- 确认空点云或无效点时不会误报最高点

重点接口：

- `GET /api/operations/points`

重点页面：

- `MonitorView`

重点字段：

- `highestPointValid`
- `highestPointCandidateCount`
- `highestPointAbsoluteX/Y/Z`
- `highestPointRelativeX/Y/Z`

重点观察：

- 监控页顶部 `最高点 Z`
- 监控页底部 `最高点坐标详情`
- 处理诊断中的补扫建议、盲区半径、环带保留率
- 补扫执行状态中的 `执行状态 / 执行动作 / 执行开始 / 执行结束 / 超时阈值`
- 预览模式与执行模式下的结果区是否一致回写分析快照

通过标准：

- 先区分“SDK 已启动”和“点云已真正出流”两个阶段：测试机日志出现 `Lidar connected` / `Tanway SDK lidar device started successfully` 只代表 SDK 已建链，不代表 WebSocket 已有点云帧
- 实机验收时必须同时看后端日志和 WebSocket：若日志持续出现 `Tanway SDK tip (8): select time out`，且 WebSocket 只有 `status` 没有 `pointCloud/globalMap/highestPoint/processingDiagnostics`，应直接判定问题仍在雷达接收链路，不要先归因前端渲染
- 当前项目现场症状正是上述情况，排障时应优先核查 UDP 包是否到达、源 IP 是否匹配、帧长度/帧头是否被 SDK 丢弃、DIF 是否成功进入 Tensor48 解码
- 当前项目固定使用 `LT_Tensor48`，该型号在 SDK 中依赖 DIF 先将 `_isLidarReady` 置为 `true` 后才会放行点云回调；若 `accepted point/dif/imu=0/0/0`，则应直接判定“还没有任何有效雷达 UDP 进入接收链路”
- 2026-04-10 已进一步实测确认：Tensor48 在线流实际 `mirror=0(A镜面)`，而 SDK 原始示例和部分文档曾写成 `1`；如果在线路径把 `PointCloudCallback(points, maxAngle, 1)` 当作分帧条件，就会导致 `OnPointCloud` 永远不触发。修正为 `0` 后，SDK demo 在测试机上已能稳定输出 `width:21359/21360 ... point cloud size: ...`
- 2026-04-10 后端服务也已按同样修正恢复成帧，`gogs-backend.service` 日志中可持续看到 `accepted point packet` 与 `PointCloudCallback ... framedSize` 由 `0` 回到非零再归零的循环，说明项目后端已经不是“连上但没帧”，而是真正收到了雷达点云流
- 2026-04-10 进一步定位前端“WebSocket 未连接”的直接原因：`backend/src/service/WebSocketServer.cpp` 明确要求连接地址带 `?token=...`，而前端 `frontend/src/stores/system.js` 之前使用裸 `new WebSocket(wsUrl)`，未附带 token，导致服务端在 `onNewConnection()` 里直接拒绝连接。已改为复用 `createWebSocket()` 的鉴权 URL，前端恢复连接后才能继续验证点云画面
- 已做过两类直接验证：一是测试机对 `192.168.0.51` 可 `arping` 成功，但抓 `udp port 5600/5700/5900` 仍为 `0 packets captured`；二是按 SDK 其他分支的控制协议手工向 `192.168.0.51:6000` 发查询帧时，仅能看到出站 UDP，未收到任何控制回包。验收和排障时应优先基于这些实机证据推进
- 已做过第三类直接验证：在测试机本地编译并运行 SDK 官方 `Demo_UseSDK.cpp`，配置仍为 `192.168.0.51 -> 192.168.0.17:5600/5700/5900`，且已先停止项目后端释放端口；官方示例仍输出 `select time out; accepted point/dif/imu=0/0/0, rejected point/dif/imu=0/0/0, frames=0`。因此若现场仍无点云，应优先排除设备出流/目标 IP/交换网络路径，而不是怀疑项目封装代码
- 绝对坐标与货场世界坐标一致
- 相对坐标与龙门/抓斗参考系一致
- 空点云时 `highestPointValid=false`
- ROI 内候选点数与现场可观测区域相符，避免把“无候选点”和“最高点无效”混为一谈
- PLC 写入最高点前，页面显示和接口值一致

## 环形可视域与盲区补偿

目标：

- 验证“垂直朝下 + 45 度盲区 + 外圈环形有效观测区”是否符合现场
- 验证慢速扫描时中心盲区会被相邻帧有效覆盖
- 验证体积补偿不会明显虚高或补偿不足

重点页面：

- `MonitorView`

重点诊断字段：

- `blindZoneRadius`
- `blindZoneAnnulusThicknessFactor`
- `blindZoneHeightQuantile`
- `ringVisiblePoints`
- `ringVisibleKeepRatio`
- `blindZoneRejectedPoints`
- `outerRangeRejectedPoints`
- `volumeSource`
- `volumeCompensatedCells`
- `volumeBlindZoneCompensation`
- `volumeBlindZoneCoverageRatio`
- `volumeBlindZoneDensityRatio`
- `volumeBlindZoneSupportRatio`

通过标准：

- 盲区半径随 `Z` 变化，趋势正确
- 盲区补偿参数与当前配置一致，现场可直接看见环厚和分位数
- 料堆中心在慢速扫描后能被有效补偿，不长期空洞
- 体积曲线连续，没有明显跳变和虚高
- `volumeBlindZoneCoverageRatio` 低时，先优先确认轨迹覆盖是否足够
- `volumeBlindZoneDensityRatio` 低时，再判断是不是该调整环厚或分位数
- `volumeBlindZoneSupportRatio` 低时，先优先看覆盖和密度哪一项更差，再决定是否调整参数
- 慢速扫描专项联调优先使用 `scripts/arm/verify_blind_zone_workflow.sh` 固定抓取 `support / coverage / density / radius` 摘要，再把参数矩阵回写到专用模板

## 轨迹窗口融合链路

目标：

- 验证轨迹切块逻辑在静止、慢速移动、停机时都稳定
- 验证尾段轨迹不会因停机丢失

重点页面：

- `MonitorView`

重点诊断字段：

- `trajectoryFlushReason`
- `lastTrajectoryFlushReason`
- `lastTrajectoryFlushFrames`
- `lastTrajectoryFlushDistance`
- `stationaryTrajectoryFlushCount`
- `directionChangeTrajectoryFlushCount`
- `distanceOrTimeTrajectoryFlushCount`
- `stopTrajectoryFlushCount`
- `trajectoryWindowActive`
- `trajectoryWindowFrames`
- `trajectoryWindowDistance`

通过标准：

- 窗口激活、累计帧数、累计距离随移动过程变化合理
- 停机后 `stopTrajectoryFlushCount` 增加，尾段入图
- 方向变化、位移阈值、静止过渡时的 `trajectoryFlushReason` 分别能回显为 `direction_change` / `distance_or_time` / `stopped`
- 长时间运行无明显切块抖动或窗口卡死

## 视频抓图与录像链路

目标：

- 验证浏览器本地抓图/录像失败时，后端兜底链路可用
- 确认现场 `GStreamer` 版本和插件足以支撑当前实现

重点接口：

- `GET /api/video/ptz/status`
- `GET /api/video/snapshot`
- `GET /api/video/recording/status`
- `POST /api/video/recording/start`
- `POST /api/video/recording/stop`

重点页面：

- `MonitorView`

重点核查：

- 云台状态条是否能明确显示配置完成度和最近错误
- 进入真实浏览器实测前，是否已先运行 `rtk bash scripts/arm/verify_browser_matrix_readiness.sh`
- 监控页顶部是否能直接显示当前实时链路为 `WebRTC` / `HLS` / 环境变量覆盖
- 如果流媒体链路本身异常，监控页顶部是否能直接显示后端返回的链路异常原因
- 如果 `WebRTC` 不可用，监控页顶部是否明确提示已经降级到 `HLS`
- 监控页顶部是否能直接显示 `MediaMTX` 健康状态
- 监控页顶部是否能直接显示 `API / HLS / WebRTC` 端口探测结果
- 监控页顶部是否能直接显示 `配置源` 是否已同步到当前 `streamPath`
- 监控页顶部是否能直接显示录像前提状态
- 浏览器、协议、编码组合的实机结果是否已经回写到 `视频实机验收矩阵模板`
- 监控页顶部是否能直接显示录像健康状态
- 监控页顶部是否能直接显示关键插件可用数量
- 如果关键插件不齐，监控页顶部是否能直接显示缺失插件名
- 监控页顶部是否能直接显示当前录像输入编码
- `/api/video/recording/status` 是否返回 `recoveryStatus / restartAttempts / lastRestartAt`
- `/api/video/recording/status` 是否返回 `retentionDays / lastPrunedCount / lastPrunedAt`
- `/api/video/self-check` 是否返回 `overallStatus / summaryMessage / checkItems`
- 前端本地截图失败后是否自动回退后端抓图
- 本地录像不可用时是否自动回退后端 `GStreamer` 录像
- 后端录像停止后是否能拿到有效 `streamUrl`
- 录制文件是否能正常播放、下载、回放

需要回写到文档的信息：

- 目标机 `GStreamer` 版本
- 关键插件是否齐全
- 现场可用的 RTSP/封装组合
- 当前默认实时链路是否稳定维持在 `WebRTC`
- 哪些场景会回退到 `HLS`
- 海康现场机型最终建议的 `recording/input_codec` 配置
- 海康视频配置基线是否采用“主码流录像 / 子码流预览 / 2K 主码流 / 720p 子码流 / 15fps~25fps”
- 监控页顶部“视频基线”是否与当前配置页的 `camera/main_stream_* / camera/sub_stream_*` 一致
- 异常退出后录像自动恢复是否触发、是否成功、重启尝试次数是多少
- 最近一次过期录像清理是否执行、清理数量是多少、清理时间是什么

### 监控页优先判断顺序

现场进入监控页后，建议固定按下面顺序判断，不要跳着看：

1. 先看“实时链路”
   用来确认当前到底是 `WebRTC`、`HLS` 还是环境变量强制覆盖。
2. 再看“链路异常”
   如果这里已经报 `mediamtx` 配置未同步、端口不可达或 RTSP 未配置，就先不要继续怀疑播放器和浏览器。
3. 再看“MediaMTX”
   如果这里已经是“配置待同步”或“异常”，先不要继续怀疑浏览器播放器。
4. 再看“端口探测”与“配置源”
   如果这里已经显示 `API/HLS/WebRTC` 某一项断开，或 `camera` 未同步，优先修复服务和配置。
5. 再看“录像前提”
   用来判断当前机器是否具备后端录像运行条件。
6. 再看“录像健康”与“录像异常”
   用来区分当前只是工具/插件未齐，还是录像进程本身已经异常。
7. 再看“插件”与“缺失插件”
   如果录像前提未就绪，优先根据这里判断缺的是工具还是具体插件。
8. 再看“录像编码”
   海康现场若默认 `H.265`，这里应优先核对为 `自动` 或 `H.265`。
9. 最后再做截图、录像、回放和 PTZ 动作验证
   先确认链路状态，再做动作验证，排障成本最低。

## 称重设备协议核对

目标：

- 确认 `ui/scale_devices` 中的寄存器映射就是现场真实协议
- 确认 `sampleTime`、采样周期和在线状态能反映真实设备节奏
- 确认重量换算系数和异常码语义有固定回写口径

固定入口：

- `rtk bash scripts/arm/verify_scale_protocol.sh`
- [`DOC/称重设备现场协议核对SOP.md`](/mnt/d/qtworkdata/gogs/DOC/称重设备现场协议核对SOP.md)
- [`DOC/称重设备协议验收记录模板.md`](/mnt/d/qtworkdata/gogs/DOC/称重设备协议验收记录模板.md)

重点字段：

- `driverStatus`
- `driverMessage`
- `onlineDeviceCount / enabledDeviceCount / totalDeviceCount`
- `registerArea / registerAddress / registerCount`
- `valueType / wordOrder / scaleFactor`
- `pollIntervalMs`
- `currentWeight / currentWeightSource / sampleTime / lastError`

通过标准：

- `verify_scale_protocol.sh` 返回 `PASS`
- 现场寄存器映射与运行态配置一致
- 三组样本称重点误差在现场验收线内
- 采样周期与心跳节奏可解释
- 异常码语义已经写入记录模板

## ONVIF PTZ 与预置位链路

目标：

- 确认球机接受当前 SOAP + HTTP Auth 调用方式
- 确认方向、速度、停止和预置位语义与现场一致

重点接口：

- `/api/video/ptz/move`
- `/api/video/ptz/relative-move`
- `/api/video/ptz/stop`
- `/api/video/ptz/home`
- `/api/video/ptz/presets`
- `/api/video/ptz/presets/goto`

重点核查：

- `pan/tilt/zoom` 方向是否和前端按钮一致
- 预置位保存、读取、跳转是否稳定
- 后端错误是否会透传到前端提示

### 海康球机优先核查点

现场摄像头如果以海康为主，建议优先按下面顺序核查：

1. 先看 `/api/video/ptz/status` 是否已经同时返回 `configured`、`ready`、`rtspConfigured`、`onvifConfigured`、`usernameConfigured`
2. 再确认 `wsSecurityEnabled` 是否与设备要求一致
3. 先做 `stop` 和 `presets` 读写，再做 `move` 和 `relative-move`
4. 最后确认 `home`、`goto preset` 和前端按钮方向是否一致
5. 抓图优先看 `/api/video/snapshot`，录像优先看 `/api/video/recording/status`
6. 如果现场相机默认输出 `H.265`，优先确认 `recording/input_codec` 已切到 `自动` 或 `H.265`
7. 打开监控页时，优先看顶部状态条是否已经同时给出“实时链路 / 链路异常 / MediaMTX / 端口探测 / 配置源 / 视频基线 / 录像前提 / 录像健康 / 插件数量 / 录像编码”十类信息

## 问题回写要求

联调时如果发现问题，按下面方式收口：

1. 先确认属于哪条链路
2. 在代码里补 `TODO` 或修复
3. 更新 `todo.md`
4. 如果属于模块长期约束，更新对应 README：
   - 点云算法：`DOC/点云算法设计README.md`
   - 补扫：`DOC/低置信度主动补扫README.md`
   - 视频：`DOC/视频链路与ONVIFREADME.md`
   - 部署：`DOC/部署与运维README.md`

## 推荐联调输出

每次现场联调至少记录这些结论：

- 设备与环境版本
- 成功链路
- 失败链路
- 稳定复现步骤
- 当前临时绕过方式
- 后续代码修复项

视频链路联调时，建议直接按 [`DOC/现场联调验收记录模板.md`](/mnt/d/qtworkdata/gogs/DOC/现场联调验收记录模板.md) 的“截图与录像”部分填写，优先回写下面这些当前页面已可直接观察到的字段：

- 监控页顶部实时链路
- 监控页顶部链路异常
- 监控页顶部 MediaMTX
- 监控页顶部端口探测
- 监控页顶部配置源
- 监控页顶部视频基线
- 监控页顶部视频自检
- 监控页顶部录像前提
- 监控页顶部录像健康
- 监控页顶部插件数量
- 监控页顶部缺失插件
- 监控页顶部录像编码
- `/api/video/recording/status` 的 `recoveryStatus / restartAttempts / lastRestartAt`
- `/api/video/recording/status` 的 `retentionDays / lastPrunedCount / lastPrunedAt`
- `/api/video/self-check` 的 `overallStatus / summaryMessage / checkItems`
- 默认实时链路是否稳定维持在 `WebRTC`
- 哪些场景会回退到 `HLS`
- `recording/input_codec` 最终建议配置
- 海康视频配置基线是否按配置页摘要执行
