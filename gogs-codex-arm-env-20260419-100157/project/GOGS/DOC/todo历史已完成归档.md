# GOGS 历史已完成事项归档

这份文档保存从旧 `todo.md` 迁出的历史完成事项、阶段性收口记录和长期实现清单。

当前剩余待办请改看仓库根目录的 [`todo.md`](../todo.md)。

## 成熟化推进入口

后续主线不再只按零散待办推进，统一以版本化成熟化文档为准：

- [系统成熟化迭代路线图](DOC/系统成熟化迭代路线图.md)
- [系统成熟化实施计划](DOC/系统成熟化实施计划.md)

当前建议优先顺序：

1. `V1.1` 视频链路现场收口
2. `V1.1` ARM 目标机构建、部署与验活收口
3. `V1.1` 设备联调模板与异常诊断收口
4. `V1.2` 一键自检、健康检查、自动恢复
5. `V1.2` 运维 SOP、升级回滚、日志与磁盘治理
6. `V1.3` 海康厂商增强能力评估与接入

## 视频链路成熟化推进 20 项

- [x] 1. 监控页实时流固定为 `WebRTC/WHEP` 优先，`HLS` 仅作降级链路
- [x] 2. 监控页顶部常驻显示实时链路、降级状态和链路异常原因
- [x] 3. 监控页顶部常驻显示录像前提、插件数量、缺失插件和录像编码
- [x] 4. 监控页顶部补齐 `MediaMTX` 健康、`API/HLS/WebRTC` 端口探测和配置源同步状态
- [x] 5. 配置页 `recording/input_codec` 补齐海康 `H.265` 场景提示与 `WebRTC` 兼容性提醒
- [x] 6. 联调 README 固化“实时链路 -> 链路异常 -> MediaMTX/端口 -> 录像前提 -> 插件 -> 录像编码”的固定判断顺序
- [x] 7. 现场联调记录模板补齐视频链路固定记录项，要求回写顶部状态与最终编码建议
- [x] 8. 配置页补齐海康视频配置基线摘要，固定主/子码流、编码、分辨率、帧率的现场建议口径
- [x] 9. 海康相机主码流/子码流、分辨率、帧率、编码格式形成统一现场配置基线
- [x] 10. 监控页或联调输出补齐“当前采用哪套海康视频基线”的可见记录
- [ ] 11. 真实摄像头环境完成 `WebRTC/HLS`、截图、录像、回放的实机验收并回写结论
- [ ] 12. 真实摄像头环境完成海康 `H.264/H.265` 浏览器兼容矩阵并回写建议
- [ ] 13. 明确哪些浏览器/现场终端允许直放 `H.265`，哪些必须转 `H.264`
- [x] 14. 后端录像健康检查形成正式实现
- [x] 15. 后端录像异常退出自动恢复形成正式实现
- [x] 16. 录像文件磁盘保留策略和清理策略形成正式实现
- [x] 17. 视频链路一键自检输出纳入 `MediaMTX/录像/PTZ/抓图` 四类状态
- [x] 18. 海康 SDK / ISAPI 增强能力边界形成正式设计文档
- [x] 19. 设备联调 SOP 明确海康接入、异常排查和回写模板
- [ ] 20. `V1.1` 视频链路现场收口项完成一次版本化验收

## 代码优先收口顺序

后续如果目标是“业务功能更完整、更稳定、边界更清楚、链路更自维护”，代码推进优先按下面顺序处理，不要和纯现场验收项混在一起：

### P0：业务主链自维护

1. 扩系统级统一自检入口，不能只停留在 `video/self-check`
   目标：把 `video / ptz / plc / scales / database / disk / process` 汇总成统一健康结论，减少现场靠人工拼状态
2. 补运行时健康留痕和恢复链路
   目标：录像、WebSocket、关键后台服务异常后，页面和接口都能看到“是否恢复、恢复了几次、当前是否阻塞”
3. 补业务主流程验收留痕
   目标：监控页、回放页、配置页、远控页都能一键导出当前关键状态，避免现场只靠截图和口头描述

### P1：边界清晰与协议收口

4. 继续压实设备协议边界
   目标：`RTSP / ONVIF / ISAPI / SDK`、`PLC / Scale / Lidar` 各自只负责自己的边界，不再把状态和错误分散到多处
5. 继续收口前后端状态口径
   目标：页面显示、接口字段、验收脚本、README 和 `todo.md` 使用同一套结论字段，不允许各说各话
6. 继续补失败原因透传和错误分级
   目标：避免“失败/未连接/待确认”这种泛化结果无法定位到具体链路

### P2：稳定性与运维闭环

7. 把自检、健康检查、恢复策略接进部署验收链
   目标：`verify-*` 脚本、页面状态、后端接口三者统一
8. 补磁盘、目录、进程、依赖缺失的运行前诊断
   目标：在现场动作开始前先发现阻塞项，而不是录像或控制失败后才报错
9. 补版本化验收与状态推进规则
   目标：代码已写、页面可见、脚本可查、文档已回写、现场已验证这几种状态明确拆开

### 当前明确属于“现场阻塞”的项

下面这些项没有真实设备就不能关闭，不要再误当成纯代码任务：

- 视频链路第 `11 / 12 / 13 / 20` 项
- 真实球机 `ONVIF PTZ`
- 真实视频源截图与录像兼容性
- 真实料堆慢速扫描盲区补偿参数验证

### 当前代码推进原则

- 先补“系统能不能自查、自报、自恢复”
- 再补“业务主流程能不能自留痕、自导出、自交接”
- 最后才补纯展示层小优化
- 任何新事实、新边界、新 workaround 都必须同步回写 `todo.md` 和对应 README

### 视频链路问题记录

- `2026-04-15`：前端此前没有消费后端 `/api/video/stream-info` 已提供的 `apiReachable / hlsReachable / webrtcReachable / mediamtxSource`，导致现场只能看到“链路异常”，看不到“服务没起 / 端口没通 / 配置没同步”的拆分状态；已纳入第 4 项并落到监控页顶部。
- `2026-04-15`：海康相机编码和码流基线仍未在真实设备环境固化，当前只能提供配置提示，尚不能替代第 8、9 项的实机验收。
- `2026-04-15`：后端配置 schema 当前没有结构化的 `主码流/子码流/分辨率/帧率` 字段，现阶段只能先把海康视频基线收口成配置页与文档摘要；已纳入第 9、10 项，后续若要做强校验需要先扩 schema。
- `2026-04-15`：现场补充确认默认摄像头主码流分辨率已提升到 `2K`，不再按 `1080p` 作为默认基线；配置页摘要、联调文档和记录模板已同步修正。
- `2026-04-15`：`camera/main_stream_*` 与 `camera/sub_stream_*` 现阶段用于固化现场联调基线和监控页摘要，还不会直接替代设备真实码流配置；如果后续要自动下发或强校验，需再补设备配置映射。
- `2026-04-15`：`/api/video/recording/status` 现已区分“录像前提”和“录像健康”，前者看工具/插件是否齐全，后者看当前是否录制中、是否降级或异常；后续自动恢复逻辑应基于 `healthStatus/healthMessage` 继续扩展。
- `2026-04-15`：后端录像异常退出后已增加“限次自动恢复”策略，并通过 `recoveryStatus / recoveryMessage / restartAttempts / lastRestartAt` 留痕；当前为保守实现，默认最多自动重启 3 次，后续若要更激进需要再评估误重启风险。
- `2026-04-15`：录像保留策略现已通过 `retentionDays / lastPrunedCount / lastPrunedAt` 对外可见，当前清理仍在“启动录像前触发”，还不是后台周期清理；如果后续要做更强治理，需要再补周期任务或磁盘阈值策略。
- `2026-04-15`：统一视频自检入口已落到 `/api/video/self-check`，当前汇总 `stream / recording / ptz / snapshot` 四类状态；后续如果脚本和前端都依赖它，应继续保持字段稳定，避免重复在多处拼装结论。
- `2026-04-15`：`scripts/verify-field-acceptance.sh` 已接入 `/api/video/self-check`；后续新增视频自检项时，优先同步更新该接口和脚本，不要再让脚本单独发明第二套结论口径。
- `2026-04-15`：浏览器兼容矩阵目前已先形成项目级草案文档和监控页“浏览器兼容”建议标签，但还不等于真实摄像头环境结论；第 12、13 项仍需实机回写后才能关闭。
- `2026-04-15`：第 11、12、13 项现已补齐统一的《视频实机验收矩阵模板》，后续真实摄像头联调必须先回写矩阵，再更新项目级兼容建议；在没有实机矩阵回写前，不应把任何浏览器 `H.265` 结论当成正式验收结果。
- `2026-04-15`：第 18、19 项已补齐《海康SDK与ISAPI能力边界》和《海康设备联调SOP》；当前结论已经固定为“SDK/ISAPI 只作为后端增强候选，不替代 Web 主播放链”，后续若正式接入必须补接口落点、配置项、错误留痕和验收项。
- `2026-04-15`：第 20 项现已补齐《V1.1视频链路版本化验收清单》，当前状态只能算“验收入口已准备”；在第 11、12、13 项没有真实现场回写前，不应把 `V1.1` 视频链路标成已通过。
- `2026-04-15`：已补齐《视频现场回写顺序卡》，用于把监控页状态检查、动作验证和文档回写压成固定执行顺序；后续现场联调应优先按顺序卡执行，避免只测单点功能就提前写通过。
- `2026-04-15`：监控页头部已新增“复制视频摘要”动作，可把当前关键视频状态一键整理成回写文本；后续现场联调应优先使用该摘要再补人工结论，减少手工抄录错误。
- `2026-04-15`：监控页顶部已新增“自检项”摘要，会直接汇总 `stream / recording / ptz / snapshot` 的拆分结论；后续若新增视频自检项，应同步更新这个摘要和复制文本，避免页面只显示总状态。

## 2026-04-16 非点云收口记录

- [x] 用户菜单移除“个人中心开发中”占位，管理员改走真实“用户与权限 / 配置中心”入口
- [x] 对齐文档、前端 TODO、模块结构文档同步到“新配置中心为主线、旧 `ConfigView.vue` 为遗留实现”的统一口径
- [x] 回写 `/api/monitor/trajectory` 已落地事实，清理过期的前后端接口缺口描述
- [x] 运行参数页吸收海康视频基线与 Tanway 官方分组说明，关键契约不再挂在旧 `ConfigView.vue`
- [x] 高级维护域将“维护操作”收紧为超级管理员入口，并同步过滤导航与首页入口
- [x] 高级维护总览改为仅超级管理员请求维护状态接口，普通管理员不再触发超管级 `/api/system/maintenance/status`
- [x] 旧 `ConfigView.vue` 已裁剪为只读迁移壳，不再保留任何可编辑产品逻辑

## 当前剩余工作

当前仓库内代码主线已经收口，剩下的工作主要是现场验证和少量设备协议落地。下一会话如果要继续推进，请优先按下面顺序处理：

1. 在真实称重设备上核对寄存器映射、心跳周期和重量换算系数
2. 在真实摄像头环境联调 `ONVIF PTZ`
3. 在真实视频源环境验证截图与录像兼容性
4. 在真实料堆慢速扫描场景验证盲区补偿参数

2026-04-19 ARM 现状补充：现网运行配置已确认切到 `192.168.0.51` 雷达 + `192.168.0.152` 摄像头，旧的 `192.168.0.52 / 192.168.0.133` 组合当前关闭。当前部署版后端仍为 `sha256=3c2283a84efa1de7bda50c5c42e43cbdcb68178981ee45da1946aa59797334e2`，首页资源为 `assets/index-Bxrnerc2.js`，`rtk bash scripts/arm/run_backend_regression.sh` 已通过；在 `51/152` 组合下，测试机 `ping` 两个设备地址均为 `0% packet loss`，`curl http://127.0.0.1/media/hls/camera/index.m3u8 | head -n 1` 返回 `#EXTM3U`，后端日志重新出现 `VideoManager: ONVIF connection state changed to connected` 与 `Tanway SDK point cloud callback`，`rtk bash scripts/arm/verify_remote.sh` 已回到 `PASS`。因此“目标 ARM 机现场外设联通状态下的完整联调验活”这一项已形成通过证据。

当前前端迁移收口约束：

- 新前端以 `origin/dev` 为基线迁移当前已验证的业务能力
- 登录恢复、WebSocket 自动重连、点云统一显示、最近窗口丢帧诊断、PTZ ready 后加载 presets 都要保留
- 最近窗口的 `recentDropRate` 口径已经调整为真实的队列挤压占比，不再按“每帧平均丢多少”去放大显示
- 前端最终浏览器显示确认由用户执行，我这边只负责把代码和部署准备到可验收状态，不代替用户做最后一轮界面实测

推进原则：

- 不要再回到已完成主线的重构或口头解释层，直接做现场项
- 每个现场项都要按“实现/验证/文档/todo”四件套收口
- 如果发现现场项依赖新的协议或硬件前提，先在 `todo.md` 里补清楚，再继续做实现
- 现场项验证完成后，立即更新 `DOC/项目完成状态说明.md` 和对应模块 README，避免状态口径漂移

新会话接手指令（可直接复制作为第一条消息）：

> 继续按 `todo.md` 的剩余项推进，优先顺序是：真实称重设备寄存器映射与换算系数核对、真实摄像头 `ONVIF PTZ`、真实视频源截图与录像兼容性、真实摄像头 `H.264/H.265` 浏览器兼容矩阵、真实料堆慢速扫描盲区补偿参数验证。
> 你需要保持自主推进，不要停下来问我方向，除非现场硬件或协议前提缺失到无法合理继续。
> 每次推进都要同时补实现、回归或静态验证、文档和 `todo.md`，并在完成后提交并推送到 `origin/master`。
> 已完成的主线包括点云处理、轨迹融合、盲区补偿、低置信度补扫、视频录像/回放、ONVIF PTZ 接口、系统维护与称重配置闭环；不要再重复做这些已收口内容。
> 当前重点是把现场项真正落地并验证，而不是继续做文档重排或口头总结。

- [x] 点云处理线程改成真实工作线程，增加待处理队列和丢帧统计
- [x] 持久化雷达 DIF 外参与运行期自动校准结果到 `config.ini`
- [x] 前端显示 `queuedFrames` / `droppedFrames` / 标定诊断
- [x] 前端 Three.js 点云视图切换为真实后端点云数据
- [x] 修复前端运行阻塞项：`BASE_URL` / `ElMessageBox` 缺失导入
- [x] 切换监控布局时重建 Three.js 画布，避免点云视图丢失
- [x] 标准化原生构建入口：补 `CMakePresets.json` 和 README 原生运行说明
- [x] 显式查找 `libmodbus`，降低 Windows 原生构建阻塞
- [x] 去掉 `M_PI` 依赖，降低 MSVC 构建阻塞
- [x] 增加原生后端构建脚本，固化 Windows / Linux 构建入口
- [x] 补齐物料历史记录闭环：`MaterialHistoryManager` + `HistoryApiHandler`
- [x] 打通体积记录闭环：`volumeCalculated -> database -> HTTP`
- [x] 补齐料堆管理闭环：`PileManager` 持久化 + `/api/piles` / `/api/material-types`
- [x] 前端 `PileManager` 接入真实后端接口，替换本地模拟数据
- [x] 前端 `HistoryView` 接入真实历史接口，移除模拟回退与写死图表
- [x] 补齐库存快照 HTTP API：`/api/inventory-snapshots*`
- [x] 前端 `InventoryView` 主表接入真实库存快照数据
- [x] 前端 `InventoryView` 快照对比接入真实 compare API
- [x] 前端 `InventoryView` 详情历史曲线接入真实快照历史数据
- [x] 前端 `InventoryView` 报告生成流程替换为真实导出/下载链路
- [x] 前端 `InventoryView` PDF 正式导出切换为浏览器打印保存链路
- [x] 前端 `InventoryView` 详情点云预览替换为真实点云资源入口
- [x] 库存快照创建时自动导出 `PCD`，并提供真实点云文件下载入口
- [x] `PlaybackView` 接入真实库存快照点云文件列表与时间轴
- [x] `PlaybackView` 点云画布替换为真实 `PCD` 数据加载与渲染
- [x] `PlaybackView` 作业事件切换为真实历史接口
- [x] `PlaybackView` 视频轨道切换为真实录像数据源
  已完成：后端录像列表补齐 `recordingMode` / `segmentIndex` / `durationLabel`，前端回放页同步展示单文件与分段语义
  已完成：后端在单文件录像停止时自动写入轻量录像索引，回放页可显示完成状态和开始/结束时间
  已完成：回放页支持按录像状态、录像模式和关键字筛选
  已完成：点击录像条目会反向定位时间轴和当前作业位置
  已完成：回放页顶部增加统一的时间范围与轨道数量摘要
  已完成：顶部摘要和分析统计卡可直接切换到对应轨道
  已完成：分析建议可直接跳转到对应轨道，顶部增加当前联动状态横幅
  已完成：作业事件列表高亮当前时间点对应事件，联动状态更明确
  已完成：右侧增加当前焦点卡，统一展示当前视频、快照和作业状态
  已完成：当前焦点卡支持直接切换视频、快照和作业轨道
  已完成：当前焦点卡、轨道标题和录像列表提供定位当前项与录像下载入口，支持录像排序
  已完成：回放视频默认选中项随当前排序首项对齐，避免排序和播放焦点不一致
  已完成：录像筛选重置会同时恢复默认排序，避免筛选和排序状态不一致
  已完成：视频轨道头部提供“下载当前”入口，减少录像下载的二次查找
  已完成：点云轨道与点云列表补齐当前快照下载入口，与录像管理体验对齐
  已完成：作业事件列表补齐“定位当前”与单条事件定位入口，和视频/快照操作对齐
  已完成：当前焦点卡补齐视频录制状态、快照可下载状态和当前作业标签
  已完成：当前视频和当前快照支持一键复制路径，方便现场排障和交接
  已完成：视频、快照和作业列表补齐“当前”标记，与焦点卡高亮一致
  已完成：回放页新动作按钮补齐窄屏换行样式，避免焦点卡和列表挤压
  已完成：路径复制补齐浏览器剪贴板失败兜底，现场无权限也能继续交接
  已完成：当前焦点卡复制摘要升级为带路径的完整交接文本，便于一键留痕
  已完成：当前作业支持单独复制摘要，方便单条作业记录交接
  已完成：回放页当前状态同步到 URL，支持分享和复现当前回放焦点
  已完成：录像筛选关键字、状态、模式和排序也同步到 URL，分享链接可恢复列表条件与焦点
  已完成：回放搜索词也同步到 URL，分享链接可恢复搜索结果
  已完成：录像列表接口下推筛选与排序参数，回放页按当前会话条件请求后端录像记录，后端排序语义与前端选项对齐
  已完成：回放搜索结果区区分作业/快照来源，点击结果会联动切换到对应轨道
  已完成：回放 URL 指向不存在的录像/快照/作业时会提示并回退到可用状态
  已完成：回放日期预设切换时会清空旧焦点、搜索词和录像筛选，避免沿用过期会话条件
- [x] `PlaybackView` 分析图切换为真实作业与快照聚合数据
  已完成：分析窗的摘要和建议已切换为当前时间范围内的真实作业、快照和录像数据驱动
  已完成：时间轴、搜索结果和作业事件跳转时会自动选中最近的录像文件
- [x] 更新设计与部署文档：统一为 ARM Linux 原生后端 + 独立前端方案
- [x] 固化开发约束：后续实现优先面向固定配置 ARM Linux 现场环境稳定运行，不为泛兼容提前过度设计
- [x] 补齐 HttpServer 静态文件服务，支持可选单机托管前端资源
- [x] 为原生运行目录补充 systemd 服务模板与启动顺序说明
- [x] 补充 ARM Linux 目标机原生运行体检脚本
- [x] 补充 systemd 服务自动安装脚本
- [x] 修正库存快照汇总口径：基于 `PileManager` 当前库存而不是历史操作反推
- [x] 修正库存快照总重量统计错误，改为汇总当前重量
- [x] 新增手动盘存测量接口：按料堆 ROI 从全局地图测量并回写库存
- [x] 补齐认证基础表与默认账户初始化，去掉登录 demo 路径
- [x] `HttpServer` 切换为真实 `/api/auth/*` 与 `/api/users*` 后端接口
- [x] 前端 `LoginView` 切换为真实登录，`user` store 补齐管理员角色辅助状态
- [x] 前端 `DashboardView` 切换为真实库存、历史、设备诊断数据
- [x] 后端补齐通用 `/api/config` 配置读写接口
- [x] 前端 `ConfigView` 切换为真实配置、物料类型和料堆数据源
- [x] 前端 `RemoteOperationView` 切换为真实料堆范围与实时高低点展示
- [x] 前端 `MonitorView` 货场俯视图切换为真实料堆 ROI 与实时点位展示
- [x] `ModbusClient` 升级为 PLC V2.0 寄存器读写与远程控制能力
- [x] `HttpServer` 正式接入 `/api/control/*` 远程控制与状态统计接口
- [x] `ModbusClient` 切换为 Qt SerialBus，移除 `libmodbus` 依赖
- [x] 移除后端未使用的 OpenCV 构建依赖，数据库访问统一说明为 QtSql
- [x] 清理前端 mock 服务器与脚本模拟数据，只保留真实前后端主线
- [x] 清理未完成的 `RemoteOperationHandler` / `PlcCommunicationManager` 草稿文件
- [x] `PileManager` 单料堆模式写回 `config.ini`
- [x] 统一 ARM Debian 11 / PCL 1.11.1 / Eigen3 3.3.9 平台基线
- [x] 修正 MSVC 下的 const 成员与容器类型推导编译错误
- [x] 补齐认证模块源码到后端构建清单，修复链接错误
- [x] 配置文件路径自动检测、创建目录并首次启动自动补全落盘
- [x] 默认配置文件固定到软件运行目录下的 `config/config.ini`
- [x] 配置文件首次生成时自动补齐数据库相关配置项
- [x] 数据库启动链支持自动建库、建表、补列与补索引
- [x] 修复 `processing/map_region_size=0` 无法切回自动区域的问题
- [x] 审计并修复 `lidar_calibration/yaw_deg`、`R`、`z` 的真实消费链路
- [x] 处理 `system/log_level`、`system/ntp_server`、`system/timezone` 的运行时接线或明确收口
- [x] 修复前端 `npm run lint` 配置缺失问题（`.gitignore` 与 ESLint Vue/ESM 解析器）
- [x] 规范跨 Windows/WSL 的前端依赖安装与构建入口
- [x] 继续拆分前端图表与 UI 相关构建产物，消除 `vite build` 的大 chunk 警告
- [x] 升级前端 Sass 调用链，消除 `vite build` 中的 `legacy-js-api` 弃用警告
- [x] 统一算法配置（高级）与运行参数的前端职责边界，消除重复编辑入口
- [x] 重构区域地图为仅维护表面层的二维网格，替换区域点云直接追加逻辑
- [x] 引入短轨迹窗口融合，将连续慢速移动帧合并为轨迹块后再更新区域表面
- [x] 为表面单元补齐 `z_mean` / `z_top` / 候选高点 / 置信度 / 方差统计与自适应融合规则
- [x] 覆盖静止、连续移动、短暂停顿、方向变化、局部稀疏和噪声高点等场景，补齐诊断输出
- [x] 完成点云现场算法总览梳理，把轨迹融合、盲区补偿、主动补扫和现场诊断放到同一套决策链里
- [x] 统一现场联调验收入口与算法总览引用，明确先看什么、怎么判断、在哪里回写
- [x] 补充点云现场算法决策树与排障顺序，现场可按现象直接定位到轨迹、体积、补偿或补扫链路
- [x] 现场联调验收记录模板补齐最高点/轨迹窗口与低置信度补扫字段，能直接回写算法总览
- [x] 完成点云显示、融合、快照、回放全链路梳理，并落文档 `DOC/点云显示与融合全链路梳理.md`

### 点云显示与回放链路问题记录

- `2026-04-16`：`PointCloudProcessor` 当前真实工作链已经是 `processFrame -> analyzeFrame -> commitFrameResult`，但 `backend/src/processing/pcl/PointCloudProcessor.cpp` 里仍保留整套未接线的 `processFrameInternal()` 旧同步全链路；同一业务存在双实现，后续继续改过滤、显示或融合逻辑时极易出现“改了一条、忘了另一条”的维护偏差，建议明确删掉或隔离废弃路径。
- `2026-04-16`：处理器仍保留 `pointCloudProcessed` / `pointCloudDisplayReady` 显示信号，但当前监控页单帧流实际是 `WebSocketServer <- LidarDriver::pointCloudReceived` 直接推原始单帧；“处理器显示云”和“监控页显示云”并不是同一条链，命名和接线很容易让排障时误以为前端看的是处理后结果，建议统一口径并清理无消费者信号。
- `2026-04-16`：`frontend/src/views/MonitorView.vue` 当前会在 `pointCloud` 和 `globalMap` 之间自动回退显示，但两者坐标语义不同：前者是雷达本地单帧，后者是世界坐标全局表面图。当前 UI 没有显式提示这件事，容易出现“模式没变但画面坐标系变了”的误判，建议补明确状态或取消跨语义自动回退。
- `2026-04-16`：`/api/monitor/trajectory` 实际由 `MaterialHistoryManager::queryMonitorTrajectory()` 查询 `material_operations.gantry_position_x/y` 生成，当前返回的是历史作业轨迹，不是处理器实时短轨迹窗口，也不是监控页实时点云轨迹；接口名和消费位置容易让人误解为“点云融合轨迹”，建议改名或在接口文档/前端文案里明确语义。
- `2026-04-16`：`frontend/src/views/MonitorView.vue` 里仍保留 `trajectoryPoints` / `showTrajectory` 结构，但搜索结果显示只有声明、传参和清空，没有真实数据加载；监控页轨迹 UI 目前处于未接线状态，建议要么补数据来源，要么移除占位结构避免误导。
- `2026-04-17`：已同步更新 `docs/system-architecture.md` 的 WebSocket 协议描述，补齐 `sequence / rawCount / displayCount / voxelSize / source` 元数据，并明确区分单帧点云、融合预览和全局地图三条显示语义；这条文档偏差已收口。
- `2026-04-16`：后端已确认不能对当前 `LT_FocusB2_64` 直接下发 SDK `0.01~360.00`，否则会因为 SDK 组帧依赖 `point.angle < m_startAngle` 而不再触发 `OnPointCloud()`；当前默认策略需要保持为“按机型的安全近全角”，即 `TW360 -> 0.01~360.0`、其它当前接入机型 -> `0.1~179.9`。如果现场画面恢复后仍存在固定方向缺口，下一优先级是核实 `tanway_sdk/lidar_config/lidar_type` 是否和实际设备一致，再调 `processing/display_frame_directional_clip_axis / half_angle / angle_offset / invert`。
- [x] 在目标 ARM Debian 11 目标机完成一次完整构建与联调验收（WSL 不执行）
  已完成：`scripts/build-native-backend.sh`、`scripts/deploy.sh`、`scripts/verify-native-runtime.sh` 和 `DOC/ARM Debian 11原生部署最终验收清单.md` 已准备齐全
  已完成：`DOC/ARM Debian 11原生部署最终验收清单.md` 已补齐 ONVIF PTZ、视频抓图/录像与盲区补偿的现场命令和判定标准
  已完成：新增 `scripts/verify-field-acceptance.sh` 与 `DOC/现场联调验收记录模板.md`，可直接执行并留痕
  已完成：新增 `scripts/verify-arm-deployment.sh`，可一键串联原生运行体检和现场联调验收，并生成总汇总报告
  已完成：2026-04-18 已通过编译机 `jamin@192.168.110.128` 完成当前工作树的 ARM 构建、后端替换和前端同步，运行中后端 `sha256=3c2283a84efa1de7bda50c5c42e43cbdcb68178981ee45da1946aa59797334e2`，`rtk bash scripts/arm/run_backend_regression.sh` 返回 `All regression checks passed`
  已完成：2026-04-19 已把测试机运行配置切到 `192.168.0.51` 雷达 + `192.168.0.152` 摄像头；`ping` 两个地址均 `0% packet loss`，`curl http://127.0.0.1/media/hls/camera/index.m3u8 | head -n 1` 返回 `#EXTM3U`
  已完成：2026-04-19 在上述设备对下，`rtk bash scripts/arm/verify_remote.sh` 返回 `PASS`，同时命中 `VideoManager: ONVIF connection state changed to connected` 与 `Tanway SDK point cloud callback`
  说明：旧的 `192.168.0.52 / 192.168.0.133` 组合当前关闭，已不再作为 ARM 现场验活默认设备对
- [x] 对照 `DOC/PLC接口通讯协议_V2.0.md` 逐项复核 PLC 读写与控制接口实现，补齐不一致项
- [x] 修正 PLC 写链路，禁止每 100ms 全量覆写 64 个保持寄存器
- [x] 按协议实现 `HR_WRITE_CONFIRM` / `HR_CMD_STATUS` / `HR_CMD_RESULT` 的真实确认与结果读取
- [x] 修正控制指令完成态判断，避免“写成功即当作执行完成”
- [x] 复核最高点、心跳和模式切换字段与 PLC V2.0 协议的语义一致性
- [x] 处理 `PLC接口通讯协议_V2.0` 中 `HR_SYSTEM_STATUS` 仅有位定义但无寄存器地址的协议缺口
- [x] 按 `PLC接口通讯协议接口速查表V1.1.docx` 修正状态字位定义与故障/急停/模式位映射
- [x] 按 `PLC接口通讯协议接口速查表V1.1.docx` 调整命令完成回退逻辑，避免强依赖未落地的 `HR_CMD_STATUS / HR_CMD_RESULT`

## Frontend UI Polish

- [x] 统一全局主题、登录页、布局壳与顶部常驻控件的基础视觉语言
- [x] 收口公共按钮组、面包屑、用户菜单、主题切换和状态指示器的居中与间距
- [x] 统一所有业务页的表格、筛选区、工具栏和卡片标题对齐
- [x] 收口所有对话框、抽屉、表单项和底部按钮区的视觉细节
- [x] 扫除首页、历史、库存、远程操作页面模板里的硬编码状态色
- [x] 最终抽查并收口图表、画布和统计配置里的剩余颜色常量
- [x] 统一加载态、空状态、提示态和弹窗底部交互
- [x] 完成主页面标题区、工具栏和表单的窄屏自适应回归
- [x] 统一共用管理组件、危险操作弹窗、404 和测试页的局部视觉细节
- [x] 统一顶部状态控件、用户菜单、主题切换和配置页算法区细节

## Documentation Modularization

- [x] 将点云算法说明从根 `README.md` 拆出为独立文档
  已完成：新增 `DOC/点云算法设计README.md`
  已完成：新增 `DOC/README.md` 作为文档索引
  已完成：根 `README.md` 改为仅保留总览和文档跳转入口
- [x] 继续拆分后端服务架构 README
  已完成：新增 `DOC/后端服务架构README.md`
  已完成：梳理 `Application` 装配顺序、设备接入层、点云处理层、库存业务层和对外服务层
  已完成：明确 `HttpServer`、`PointCloudProcessor`、`MaterialHistoryManager`、`PileManager`、`DatabaseManager` 的职责边界
- [x] 继续拆分视频链路与 ONVIF README
  已完成：新增 `DOC/视频链路与ONVIFREADME.md`
  已完成：梳理 RTSP/HLS 回放、ONVIF PTZ/预置位、前端截图/录像优先路径、后端抓图兜底
  已完成：明确 `VideoManager`、`HttpServer`、`MonitorView`、`api.js` 的职责边界
- [x] 继续拆分 PLC 控制链路 README
  已完成：新增 `DOC/PLC控制链路README.md`
  已完成：梳理输入/保持寄存器主线、命令确认链、远控会话和前后端职责分工
  已完成：明确 `ModbusClient`、`HttpServer`、`api.js`、`RemoteOperationView` 的边界
- [x] 继续拆分部署与运维 README
  已完成：新增 `DOC/部署与运维README.md`
  已完成：梳理运行目录、开发机构建入口、ARM 目标机部署入口、systemd 主线和运行时验证脚本
  已完成：明确部署脚本、systemd、后端运行时和数据库/视频服务之间的职责边界
- [x] 继续拆分前端模块结构 README
  已完成：新增 `DOC/前端模块结构README.md`
  已完成：梳理路由壳、页面层、组件层、服务层和 Pinia 状态层的数据边界
  已完成：明确 `MonitorView`、`RemoteOperationView`、`api.js`、`system/user/theme/featureSwitches store` 的职责范围
- [x] 继续拆分现场联调验收 README
  已完成：新增 `DOC/现场联调验收README.md`
  已完成：把 PLC、最高点、环形可视域、轨迹窗口、视频录像和 PTZ 的现场验收项独立收口

## Stability Hardening

- [x] 打通 Windows 本地后端回归测试运行链，确保 `GrabSystemRegressionTests` 可直接执行
- [x] 清理 `MonitorView` 搜索、批量盘点、边界导入导出和视角预设假动作，改为真实接口或真实本地持久化
- [x] 补齐 `MonitorView` 本地录像、视频截图和 PLC 写入真实控制链路
- [x] 补齐 `MonitorView` 云台控制与视频预置位真实接口
- [x] 打通 `PTZ/预置位` 失败原因透传，前端优先展示后端真实错误
- [x] 收口 `HighestPointDetector` 正常失败分支日志噪音，避免空点云/空 ROI 刷 warning
- [x] 用用户提供的 Windows Qt/CMake 命令完整构建后端，验证 `VideoManager` / `HttpServer` 最近 PTZ 相关改动可通过 MSVC Release 编译
  命令：先设置 `Qt6_DIR`、`PCL_DIR`、`Eigen3_DIR`，再执行 `scripts\\build-native-backend.bat backend-win-msvc-release`
  验收：`backend-win-msvc-release` 配置与编译均成功，`VideoManager.cpp` / `HttpServer.cpp` 的 PTZ 相关改动可在 MSVC Release 下通过
  说明：当前会话已确认 Windows 预设名为 `backend-win-msvc-release`，不要误用 debug 预设；已由用户本地编译验证通过
- [x] 补充后端视频抓图接口
  已完成：后端提供 `GET /api/video/snapshot`，通过 ONVIF `GetSnapshotUri` 代抓相机快照并透传真实错误
  已完成：`MonitorView` 在本地 `drawImage` 失败或视频元素不可截图时自动回退到后端抓图下载
  说明：该链路依赖相机暴露可用的 ONVIF Snapshot URI；若实机要求额外鉴权方案，继续在后续联调项中处理
- [x] 补充后端录像/导出接口
  目标：为 `MonitorView` 提供浏览器 `captureStream` 不可用时的录像兜底能力
  背景：当前仅支持浏览器本地 `MediaRecorder`，受浏览器和视频源限制
  方案优先级：ARM Linux 目标机优先采用 `GStreamer` 录制链路，`ffmpeg` 仅作为开发机或备用方案，不作为当前主实现前提
  已完成：后端新增 `GET /api/video/recording/status`、`POST /api/video/recording/start`、`POST /api/video/recording/stop`
  已完成：`VideoManager` 使用 `QProcess + gst-launch-1.0` 承接后端录像，默认落盘到 `data/videos/yyyyMMdd/HHmmss.mp4`
  已完成：`MonitorView` 在浏览器 `captureStream` 不可用或本地录像启动失败时自动回退到后端 `GStreamer` 录像
  已完成：停止后端录像后直接返回 `streamUrl`，前端可直接下载文件
  TODO：当前按 `RTSP/H264 -> MP4` 最小主线实现，H265/MJPEG 和长时分段录像需结合现场 `GStreamer` 插件能力继续扩展
- [x] 强化现场验收脚本留痕
  已完成：`scripts/verify-field-acceptance.sh` 已补齐 `GStreamer` 工具与插件检查、`/api/video/recording/status` 可执行体可用性、`allChecksCompleted` 完整性、关键插件逐项可用性、`/api/video/ptz/status` 最近动作留痕、`/api/scales/status` 连通性核查
  已完成：验收脚本现在会直接报出录像输入编码的当前值，便于现场核对自动/H.264/H.265 的实际选项
  已完成：验收脚本输出会同步写入报告文件，便于 ARM 目标机现场回归和交接
- [x] 监控页显示录像前提完整性
  已完成：`MonitorView` 顶部直接显示录像前提是否就绪、关键插件可用数量，以及 `gst-launch` / `gst-inspect` 缺失提示，现场无需额外查看接口就能判断录像链路前提
- [x] 监控页显示 PTZ 配置完成度
  已完成：`MonitorView` 云台卡片直接显示 `RTSP`、`ONVIF` 和账号三项配置完成度，现场可快速定位云台联调阻塞点
- [x] 监控页显示 WS-Security 启用状态
  已完成：`MonitorView` 云台卡片直接显示 `WS-Security` 是否启用，便于确认海康类设备是否走到了 UsernameToken 安全头链路
- [x] 独立称重设备实时采集链路接入
  已完成：后端 `ScaleManager` 已改成主动轮询式采集桥，按 `ui/scale_devices` 中的串口/网口 Modbus 配置连接真实设备并回填实时重量、采样时间、硬件在线状态和错误信息
  已完成：`ConfigView` 已补齐 Modbus 值类型、字序和采集周期配置，实时区改为优先展示后端硬件采集结果，保留本地回退预览
  已完成：后端 `/api/scales/status`、`/api/scales/devices`、`/api/scales/readings` 保持统一边界，支持外部驱动兜底上报
  已完成：称重设备配置与运行态字段已拆分，保存配置时会剥离硬件在线状态和错误信息，避免把运行态写回配置
  已完成：回归测试已补到称重设备的运行态合并与实时状态字段
  仍需现场：接入真实串口/网口称重设备并按现场协议核对寄存器映射、心跳周期和重量换算系数
- [ ] 在真实摄像头环境联调 `ONVIF PTZ`
  范围：`/api/video/ptz/move`、`/relative-move`、`/stop`、`/home`、`/presets*`
  核查项：设备是否接受当前 SOAP + HTTP Auth 方案、速度方向是否正确、预置位读写是否兼容
  补充：海康等要求 WS-Security 的设备现在可自动附加 UsernameToken Digest 安全头
  已完成：`VideoManager` 已支持 WS-Security、snapshot 兜底与 PTZ 请求主线，回归测试已覆盖 SOAP 封包与抓图解析
  已完成：后端新增 `/api/video/ptz/status`，前端可直接查看云台配置完成度和最近错误
  已完成：`/api/video/ptz/status` 现在还返回最近动作、动作时间和成功标记，前端联调时可直接看到最后一次 PTZ 操作
  已完成：对应现场动作和验收标准已整理进 `DOC/ARM Debian 11原生部署最终验收清单.md`
  已完成：`scripts/verify-field-acceptance.sh` 已支持预置位、基础连通和现场人工动作留痕
  已完成：海康球机优先核查顺序已整理进 `DOC/现场联调验收README.md`
  仍需现场：拿真实球机确认方向、速度、停止和预置位读写兼容性
- [ ] 在真实视频源环境验证截图与录像兼容性
  核查项：跨域截图失败回退、`captureStream` 可用性、导出文件格式和大小、长时录像稳定性
  核查项：ARM Linux 主机上实际 `GStreamer` 版本、关键插件、录像管线和开始/停止/状态查询 API 是否可用
  输出要求：将 ARM 主机上实测可用的 `GStreamer` 版本、插件依赖、录制命令/API 组合回写到 `DOC/视频链路与ONVIFREADME.md` 和 `DOC/部署与运维README.md`
  说明：该项依赖真实相机/HLS 源，WSL 不执行
  已完成：后端录像/抓图主线与回归测试已补齐，前端也已具备本地失败回退后端的路径
  已完成：`GET /api/video/recording/status` 已补 `gst-launch` / `gst-inspect` 可执行性和 `rtspsrc`、`h264parse`、`mp4mux`、`splitmuxsink`、`qtmux` 插件检查结果，现场可直接用接口核对录像前提
  已完成：后端录像输入编码已可在 `recording/input_codec` 中选择 `自动`、`H.264` 或 `H.265`，默认自动探测，海康默认 H.265 机型也可手动切换
  已完成：回归测试已补 `H.265` 录像参数生成、`HEVC` 别名归一化和 `auto` 默认 H.264 回退，避免管线回退成 `rtph264depay`
  已完成：监控页录像条常驻显示当前输入编码，现场无需开始录像也能确认编码配置
  已完成：`recordingSaveDays` 已接入后端录像启动前清理，历史 MP4 会按保留天数自动回收
  已完成：`recordingSegmentDuration > 0` 时接入 `splitmuxsink` 分段主线，`0` 时回退到单文件录像，前端可见当前录像模式
  已完成：对应 `GStreamer` 版本和插件检查命令已整理进 `DOC/ARM Debian 11原生部署最终验收清单.md`
  已完成：`scripts/verify-field-acceptance.sh` 已支持基础 GStreamer 插件检查和可选主动录像测试留痕
  已完成：`scripts/verify-field-acceptance.sh` 已补 `PTZ` 配置完成度与 `GET /api/video/snapshot` 抓图兜底核查
  仍需现场：用真实视频源和 ARM 主机实测 `GStreamer` 版本、插件和长时稳定性
- [x] 系统安全加固：认证、传输、部署、请求处理全链路防护
  已完成：JWT 密钥从硬编码改为 `config.ini [security]` 段读取，空值自动生成随机密钥并警告
  已完成：密码哈希从 `SHA256(password+salt)` 升级为 `PBKDF2-HMAC-SHA256`（默认 10 万轮迭代）
  已完成：随机数生成从 `QRandomGenerator::global()` 改为 `QRandomGenerator::system()`（密码学安全）
  已完成：HTTP 统一鉴权拦截，除 `/health` `/api/status` `/api/auth/login` `/api/auth/refresh` 白名单外全部需 Bearer Token
  已完成：HTTP 响应统一注入安全头：`X-Content-Type-Options`/`X-Frame-Options`/`X-XSS-Protection`/`Referrer-Policy`/`Permissions-Policy`
  已完成：WebSocket 连接必须携带有效 `token` 参数，无效直接关闭
  已完成：HTTP 请求体 10MB 大小限制 + 12MB 缓冲区上限 + 413 Payload Too Large 响应
  已完成：HTTP 空闲连接 5 分钟超时自动断开 + 30 秒周期清理
  已完成：Nginx 生产配置加固：CSP/X-Frame-Options/server_tokens off/隐藏文件拒绝/请求体限制/WebSocket 超时
  已完成：前端 WebSocket 连接自动附加 token 参数
  已完成：前端 localStorage 只存 id/username/role/real_name 四个必要字段，去除 email/phone/ip 等敏感数据
  已完成：`config.ini` 新增 `[security]` 段，关键配置标注生产环境需修改
  已完成：远程控制会话共享状态加 QMutex 保护，防止并发请求竞态
  已完成：API 错误信息不再泄露数据库内部细节（query.lastError().text() 改为 qWarning 日志 + 用户友好提示）
  已完成：输入校验：分页上限（pageSize≤100, limit≤1000）、PTZ 值 clamp [-1,1]、控制方向/速度范围限制、浮点 NaN/Inf 防护
  已完成：/api/system/info 移除认证白名单豁免，现在需要有效 token
  已完成：PUT /api/features/:type 增加 system:* 权限校验，非管理员无法修改功能开关
  已完成：分页 offset 计算改用 qint64 防止大页码溢出
  已完成：配置备份快照中 camera/password、camera/rtsp_url、database/password 自动脱敏为 ******
  已完成：mysqldump 备份前校验数据库配置值不含 shell 特殊字符，可疑时跳过导出并警告
  已完成：远程控制会话 30 分钟无活动自动释放，PLC 切回手动模式
  已完成：PileManager 8 处持锁 emit 信号改为先 unlock 再 emit，消除非递归 mutex 死锁风险
  已完成：ModbusClient::m_connected 改为 std::atomic<bool>，跨线程读写内存安全
  已完成：CORS Origin 从裸回显改为白名单校验（localhost + config 驱动扩展），非白名单域名的浏览器请求被阻断
  已完成：WebSocket 连接增加 Origin header 校验，非白名单域名直接拒绝
  已完成：VideoManager 录像进程清理确保先 terminate/kill 再 deleteLater，防止僵尸进程
  已完成：RescanCoordinator 补扫超时回调 emit 移出 mutex 锁范围，消除死锁风险
  已完成：systemd 服务添加安全沙箱指令（NoNewPrivileges/ProtectSystem=strict/PrivateTmp 等 9 项 + ReadWritePaths 精确控制）
  已验证安全：WebSocketServer（单线程事件循环串行执行，无竞态）、DatabaseManager（主线程独占，无跨线程 DB 访问）
  已验证安全：ModbusClient lambda 捕获使用 QPointer guard 保护 + &loop context 自动断开
  已验证安全：ScaleManager 边界检查完整，decodeScaleRegisters 对寄存器数量有前置校验
  已完成：Content-Disposition 文件名注入防护（移除 \r\n\"\\ 字符，3 处端点）
  已完成：DatabaseManager QSqlQuery 构造统一使用显式 m_db 连接参数
  已完成：nginx 静态资源 location 块安全头丢失修复（add_header 在嵌套块会替换父级）
  已完成：前端契约测试集成（9 项 node:test，npm test 可运行）
  已完成：PLC 控制指令审计日志（move/goto/stop/emergency/reset/clear-fault/mode 7 个端点）
  已完成：配置变更审计日志（POST /api/config 记录操作者 IP 和变更 key 列表）
  已完成：系统重启审计日志（POST /api/system/maintenance/restart 记录操作者身份）
  已完成：16 个 POST 处理器 JSON 体验证补齐（parseJsonObject helper 统一校验）
  已完成：CMake 编译器工业级告警开关（-Wall -Wextra -Wpedantic -Wshadow 等 10 项）
  已完成：AuthManager 安全配置 JSON 解析空值校验 + 3 处未检查 query.exec() 补齐
  已完成：PileManager 8 处 QSqlDatabase::database() 改为 m_dbManager->database() 显式连接
  已完成：PileManager updateMaterialType 检查 savePileToDatabase 返回值
  已完成：HTTP sendResponse 补齐 204/413/502 状态码文本 + socket 写入错误检测
  已完成：IP 限流中间件（认证端点 10次/分钟、控制端点 120次/分钟，429 Too Many Requests）
  已完成：健康检查增强（/health 返回数据库/PLC/激光雷达/视频组件状态，支持 degraded 降级报告）
  已完成：数据库自动重连（ensureConnected + SELECT 1 心跳检测 + 连接参数持久化）
  验收：所有 `/api/*` 路由未携带有效 token 返回 401；WebSocket 无 token 连接被拒绝；部署需设置 `.env` 密码

## Ring Visibility Model

- [x] 按“垂直朝下 + 45 度中心盲区 + 环形有效观测区”接入点云主处理链
  已完成：新增环形可视域过滤工具，按 `blindRadius = pose.z * tan(blindConeDeg)` 剔除中心盲区
  已完成：`PointCloudProcessor` 在外参变换后、时序边界前引入环形可视域过滤
  已完成：诊断输出补充 `blindZoneRadius`、`ringVisiblePoints`、`blindZoneRejectedPoints`、`outerRangeRejectedPoints`
  已完成：最高点高度继续直接取过滤链后高置信度可见点的 `z` 作为近似值
  已完成：配置接入 `processing/ring_visibility_filter_enabled`、`processing/lidar_blind_cone_deg`、`processing/lidar_max_visible_radius`
  已完成：回归测试覆盖 45 度盲区半径和环形点过滤行为
- [x] 补偿中心盲区未观测区域对体积估算的影响
  已完成：`PointCloudProcessor` 体积估算优先使用 `GlobalMapManager` 融合表面图，避免继续按单帧环带直接积分
  已完成：`VolumeCalculator` 新增中心盲区保守补偿，按盲区外一圈样本分角度取低分位高度填补残余空洞
  已完成：体积诊断补充 `volumeSource`、`volumeCompensatedCells`、`volumeBlindZoneCompensation`、`volumeBlindZoneSupportRatio`
  已完成：体积 `confidence` 现在会随盲区支撑不足进一步下降，避免支撑弱时仍显示高置信度
  已完成：回归测试覆盖中心盲区补偿行为和保守上界约束
  说明：该补偿建立在“行车缓慢移动时，盲区中心会被前后帧环带扫过”的现场假设上

- [ ] 在真实料堆慢速扫描场景验证盲区补偿参数
  核查项：`annulusThickness`、角度分桶数量、低分位高度是否在不同料型下稳定
  目标：避免补偿过强或补偿不足，确保体积曲线平滑且不虚高
  说明：该项依赖真实轨迹和料堆形态，先保留为人工联调项
  已完成：盲区补偿代码、诊断、回归测试和调参范围已收口
  已完成：`volumeBlindZoneCoverageRatio` / `volumeBlindZoneDensityRatio` 已补充，可直接拆看覆盖和密度
  已完成：`volumeBlindZoneSupportRatio` 已改为同时反映扇区覆盖和环带样本密度，并按环带厚度归一化，避免慢速扫描单点扇区被误判为支撑充分
  已完成：`confidence` 已改为同时考虑覆盖和密度，覆盖不足会更快拉低置信度
  已完成：`blind_zone_support_low` 补扫建议已接入归一化后的支撑率触发
  已完成：真实料堆慢速扫描时的记录项与验收标准已整理进 `DOC/ARM Debian 11原生部署最终验收清单.md`
  已完成：`DOC/现场联调验收记录模板.md` 已为盲区补偿结果留出标准记录位
  仍需现场：在真实料堆和慢速扫描轨迹下确认最终参数取值

- [x] 设计“低置信度区域主动补扫”能力
  背景：若中心盲区或某块区域点云置信度不足，系统理论上可以主动控制行车移动到合适位置重新扫描
  核心约束：
  - 必须先判断当前是否正在抓取、放料、远控或执行其他正式作业
  - 主动作业扫描不能抢占高优先级业务动作，尤其不能打断实际生产作业
  - 需要区分“建议补扫”和“允许自动补扫”两种模式，避免默认自动接管设备
  需要梳理的设计点：
  - 低置信度判定入口放在哪里：`PointCloudProcessor` 诊断、`MaterialHistoryManager` 盘存结果还是独立调度器
  - 补扫触发条件：整体 ROI 置信度不足、局部网格空洞过多、最高点不稳定、体积补偿比例过高
  - 作业互斥条件：当前 PLC 作业阶段、远控会话占用、自动任务状态、急停/故障状态
  - 优先级模型：人工作业 > 安全停机 > 正式自动作业 > 主动补扫
  - 执行动作：只发“建议目标位姿”，还是允许系统闭环发起 `/api/control/goto`
  - 停止条件：达到目标位姿、局部置信度恢复、超时、人工接管、故障触发
  - 结果回写：补扫前后置信度、补扫耗时、是否改善体积/最高点稳定性
  候选落点：
  - 新增独立的补扫调度器，避免把控制编排直接塞进 `PointCloudProcessor`
  - 由 `HttpServer` / 控制链提供只读状态和受控执行接口，算法层只提出“需要补扫”的建议
  当前结论：
  - 这不是单纯算法问题，而是“算法诊断 + 控制调度 + 作业优先级”联合设计问题
  - 在明确优先级、互斥条件和安全边界前，不应直接实现自动补扫
  已完成：已拆出 `DOC/低置信度主动补扫README.md`，把触发判据、优先级、互斥条件、接口边界和推荐架构单独收口
  已完成：`processingDiagnostics` 已补充 `rescanSuggested / rescanSuggestedReason`，先以只读建议形式输出补扫判据
  已完成：监控页和首页已接入“建议补扫”提示，当前只做诊断与提示，不自动触发控制
  已完成：补扫建议已从“单帧即报”收口为“连续帧触发 + 冷却期”模型，减少现场抖动误报
  已完成：处理诊断已补充 `rescanSuggestionConsecutiveFrames / rescanSuggestionCount / rescanCooldownRemainingFrames`
  已完成：后端已补充 `GET /api/rescan/status`，统一返回只读补扫状态、原因和是否具备控制资格
  已完成：监控页已接入 `/api/rescan/status`，可直接查看当前是否具备补扫控制资格及阻塞原因
  已完成：`/api/rescan/status` 已补充 `blockedReason / suggestedTarget`，先用保守规则返回建议目标位姿
  已完成：后端已补充 `POST /api/rescan/analyze`，补扫分析现在有独立入口
  已完成：补扫分析已补充 `suggestionPriority / suggestionConfidence`，监控页可直接查看建议强度和目标偏移量
  已完成：`RescanCoordinator` 最小骨架已落地，当前负责统一承接补扫分析快照，不直接执行控制
  已完成：前端已抽出 `frontend/src/utils/rescan.js`，首页和监控页统一消费补扫分析字段
  已完成：`HttpServer` 中分散的补扫状态拼装逻辑已收口到 `RescanCoordinator`
  已完成：`RescanCoordinator` 已补 `RescanExecutionRequest / RescanExecutionResult / RescanCancelResult`，为后续 execute/cancel 固化数据边界
  已完成：补扫分析已补 `coordinatorState / executionState / analysisRevision / updatedAt`，为后续执行状态机留稳定输出
  已完成：`/api/rescan/execute` 与 `/api/rescan/cancel` 已区分 preview 与真实执行，当前已接通 `goto/stop` 控制链路
  已完成：监控页已显式区分“预览模式 / 执行模式”，不会把真实执行误判为 preview
  已完成：补扫链路已补统一 `controlPhase` 字段，`status/analyze` 明确为 `analysis_only`，preview 返回为 `preview_only`，真实执行返回为 `live_control`
  已完成：`execute/cancel` 返回均附带当前 `analysis` 快照，后续前端执行入口可直接复用
  已完成：`HttpServer` 中 `status/analyze` 的补扫分析拼装已收口到 `buildLatestRescanAnalysis()`，减少后续真实执行接入时的双路漂移
  已完成：监控页已补“刷新分析 / 执行补扫 / 停止补扫”入口，执行时会要求持有当前控制会话
  已完成：监控页实时日志已补充补扫分析/执行动作记录，现场可直接回看调用结果
  已完成：preview 返回已补 `requestedBy / requestReason / targetPose` 回显，监控页可直接核对本次预览请求
  已完成：PLC 位姿无效时，补扫分析不再返回误导性的 `suggestedTarget`，监控页会明确显示 `--`
  已完成：无建议目标时，监控页预览执行请求不再携带伪造 `0/0` 目标，结果展示也明确显示 `--`
  已完成：监控页和补扫结果已显示 `analysisRevision / updatedAt`，便于现场判断分析新鲜度
  已完成：监控页已把补扫结果区分为“预览模式 / 执行模式”，避免与真实执行混淆
  已完成：`execute/cancel` 已接真实控制链路，并补齐完成态回写与超时监测，`commandCompleted / commandFailed / heartbeatTimeout / disconnected` 会驱动状态收敛
  待现场验证：在 ARM Linux 目标机上确认补扫执行的完成态回写时序、超时态和前端展示是否与真实 PLC 行为一致

## Workspace Follow-up

- [x] 当前工作区阶段性改动按“实现 + 回归测试 + 文档 + todo”一起归档
- [x] 先前未归档的 `PointCloudProcessor / ModbusClient / VolumeCalculator / regression tests` 已独立提交收口
- [x] 验证 `PointCloudProcessor` 轨迹窗口互斥锁改造
  范围：`m_trajectoryMutex`、`flushTrajectoryWindowLocked`、`appendToTrajectoryWindow`
  风险：处理线程与停止流程之间可能出现锁顺序问题、窗口状态竞争或停机时残留轨迹窗口未清空
  已核实：当前代码里 `m_mutex` 与 `m_trajectoryMutex` 没有出现稳定的 ABBA 反向加锁链；`processFrameInternal()` 先复制运行参数再释放 `m_mutex`，随后才进入轨迹窗口路径
  已完成：`stopProcessing()` 现在会先安全 flush 尾段轨迹窗口，再补进地图，不再直接丢弃最后一段轨迹块
  已补充：回归测试已覆盖停机时必须刷新尾段轨迹块入图
  已完成：处理诊断已补充 `trajectoryFlushReason / lastTrajectoryFlushReason / lastTrajectoryFlushFrames / lastTrajectoryFlushDistance`
  已完成：处理诊断已补充 `stationaryTrajectoryFlushCount / directionChangeTrajectoryFlushCount / distanceOrTimeTrajectoryFlushCount / stopTrajectoryFlushCount`
  已完成：处理诊断已补充 `trajectoryWindowActive / trajectoryWindowFrames / trajectoryWindowDistance`
  已完成：监控页已展示最近一次轨迹刷新原因、帧数、距离和停机收尾次数，现场可直接观察切块行为
  已完成：监控页已展示轨迹窗口当前激活态、累计帧数和累计距离，方便现场核对切块时序
  已补充：回归测试已覆盖方向变化切块、距离/时间切块和静止过渡切块，轨迹窗口状态不再只靠现场观察
  已补充：回归测试已覆盖空停机路径 `stop_empty`，避免把无尾段停机误当成异常切块
  关注点：剩余风险集中在长时运行下的锁顺序、窗口状态竞争和真实停机时序验证
  验收：构建通过，连续运行时无死锁，`trajectoryWindowActive/Frames/Distance` 诊断值稳定
- [x] 验证 `PointCloudProcessor` 新的最高点检测接线
  范围：`buildPoseTransform(pose)`、`tryDetectHighestPoint(...)`
  风险：姿态变换入口切换后可能影响最高点坐标系；空点云情况下 `HighestPoint.valid` 语义已改变，需要确认前端显示与 PLC 写链路不回归
  已核实：当前最高点写 PLC 已受 `point.valid` 保护，不会在空点云时继续写入旧高点；但 `buildPoseTransform(pose)` 引入了 `theta/z` 变换，仍需实机确认坐标系方向一致
  已补充：回归测试已显式约束 `buildPoseTransform()` 的 XY 旋转与 Z 平移同时生效，避免后续再退回仅平移变换
  已完成：`PointCloudProcessor` 现在将最高点的 `relative` 坐标按 `buildPoseTransform(pose).inverse()` 还原为真正的局部坐标，避免旋转位姿下仅做 XYZ 相减导致的坐标漂移
  已处理：修复 `processFrameInternal()` 运行时配置复制时遗漏 `groundFittingMethod` 的问题，避免自动标定和诊断退回默认分支
  已补充：回归测试已覆盖 `processingDiagnosticsUpdated.groundFittingMethod` 必须反映当前配置
  已完成：处理诊断已补充 `highestPointValid / highestPointAbsolute* / highestPointRelative*`，便于现场直接核对最高点坐标系
  已完成：监控页和首页告警已补充最高点无效、盲区半径、环带保留率、盲区补偿支撑率等观测项，方便实机联调时直接判断“未扫到”还是“坐标错了”
  已完成：`/api/operations/points` 已补充明确的 `absoluteX/Y/Z` 与 `relativeX/Y/Z` 字段，避免旧 `x/y/z` 语义不对称造成误判
  已完成：处理诊断已补充 `highestPointCandidateCount`，监控页和现场联调文档可直接核对最高点 ROI 候选点数
  验收：最高点绝对/相对坐标与料堆场景一致，空点云时不误报有效点
- [x] 验证 `PointCloudProcessor` worker pool 与 HTTP 主循环互斥锁死锁
  范围：`PointCloudProcessor::run()`、`snapshotFrameAnalysisInput()`、`enqueueFrameForAnalysis()`、`HttpServer` 连接处理
  风险：worker 线程若在持有 `m_mutex` 时再调用 `snapshotFrameAnalysisInput()` 或启动分析任务，会把主线程的 `enqueueFrameForAnalysis()` 一起卡住，进一步拖死 Qt 事件循环，让 `/health`、`/api/auth/login`、`/api/system/info` 和 websocket 看起来像“未连接”
  已核实：通过 `gdb` 附加到测试机运行中的 `GrabSystem`，确认主线程阻塞在 `enqueueFrameForAnalysis()` 的 `m_mutex`，worker 线程同时在 `snapshotFrameAnalysisInput()` 等待同一把锁，属于点云 worker 池的自死锁
  已完成：`PointCloudProcessor::run()` 已改为先在锁内收集待启动任务到本地列表，再释放 `m_mutex` 后再做 `snapshotFrameAnalysisInput()` 和任务启动，避免锁内再入锁
  已完成：修复后测试机 `http://100.105.175.44:8080/health` 和 `/api/auth/login` 已恢复快速响应，后端点云回调继续正常输出
  已完成：`HttpServer` 已补 `[HTTP]` 生命周期日志，便于后续直接从本机 curl / 浏览器日志判断请求是否进入后端
  已完成：HTTP 响应已恢复 `keep-alive`，并去掉逐 chunk 的高频 `readyRead` 日志，减少连接抖动和日志噪声
  验收：后端进程存活时 `/health`、`/api/auth/login`、WebSocket 握手都应能稳定响应；若再出现“浏览器显示未连接”，优先排查浏览器 token/origin，而不是先怀疑服务进程
- [x] 验证统计滤波参数保护与日志量
  范围：`statisticalOutlierFilter(...)`
  风险：无效参数时现在会打 warning，若运行期频繁触发可能造成日志刷屏
  已核实：前端配置入口已经对 `meanK/stddev` 做了下限保护，理论上只会在旧配置文件、手工改配置或热更新脏值场景触发
  已完成：`processingDiagnostics` 已补充 `invalidSorConfigCount` 计数，监控页和首页告警可直接看到无效统计滤波参数累计次数
  已补充：回归测试已覆盖无效统计滤波参数必须进入诊断计数
  已补充：回归测试已覆盖 `invalidSorWarningCooldownRemainingFrames`，确认 warning 只在首帧发出并进入冷却
  已完成：无效统计滤波参数的 warning 已加冷却抑制，监控页可直接看到 `invalidSorWarningCooldownRemainingFrames`
  验收：异常参数时行为可解释，正常运行时日志无持续刷屏
- [x] 验证 `ModbusClient` 位置有效性收紧后的兼容性
  范围：`PlcData::isValid()`
  风险：新增 `posZ` 范围校验后，历史 PLC 数据或初始化值可能被判无效，进而影响龙门位姿、最高点写入和地图更新
  已核实：`processInputData()` 当前在 `isValid()` 失败时直接丢弃整帧 PLC 数据，不会写入降级值；如果 PLC 冷启动阶段 `posZ` 异常，系统会继续沿用上一次有效位姿
  已补充：回归测试已覆盖 `GantryPose` / `PlcData` 的最小值、最大值边界仍然判定为有效，避免把合法极限位姿误杀
  已完成：`CommStatistics` 已补充 `invalidPoseFrames` 计数，`/api/control/statistics` 可直接返回无效 PLC 位姿累计帧数
  已完成：远程操作页已展示 `invalidPoseFrames`，现场可直接观察位姿被丢弃的累计次数
  已完成：`CommStatistics` 已补充 `invalidPoseConsecutiveFrames` 和 `lastInvalidPoseTime`，可区分偶发脏值与持续失真
  已完成：远程操作页已展示连续丢弃帧数与最近一次无效时间，便于现场排障
  已完成：`CommStatistics` 已补充 `invalidPoseAlertActive` / `invalidPoseAlertThresholdFrames` / `invalidPoseAlertCount` / `lastInvalidPoseAlertTime`，持续失真可直接在界面上看到一次性告警
  已完成：远程操作页已展示持续失真告警条和阈值信息，现场可一眼区分“偶发丢帧”和“连续失真”
  已补充：回归测试已覆盖无效 `posZ` 不会覆盖上一次有效位姿，恢复正常后 `getLatestPose()` 再回到最新有效值
  已补充：回归测试已覆盖无效 PLC 位姿必须进入通信统计计数
  已补充：回归测试已覆盖持续无效位姿会触发一次性告警，恢复正常后告警状态自动清除
  验收：PLC 实际运行时位姿仍能稳定更新，不会因 `Z` 初始化值或边界值被全部丢弃
- [x] 继续收口盲区补偿参数的现场调优
  范围：`processing/blind_zone_annulus_thickness_factor`、`processing/blind_zone_height_quantile`
  已完成：参数已接入运行配置、监控页可观测、处理诊断可回显
  已补充：调参经验范围已写入 `DOC/点云算法设计README.md`，现场优先沿 `2.0~4.0` / `0.20~0.35` 试探
  已补充：回归测试已覆盖环厚、分位数和自动扇区解析的行为边界，便于区分“参数过保守”还是“现场覆盖不足”
  关注点：不同料型下环厚和分位数是否需要进一步收敛
  验收：现场调参后体积曲线稳定，无需改代码即可完成参数收口
- [x] 为 `PlcData::isValid()` 的 Z 边界收紧补充回归测试
- [x] 验证 `VolumeCalculator` 多边形求交 epsilon 调整
  范围：`isPointInPolygon(...)`
  风险：水平边跳过策略会改变边界点归属，需要确认体积积分边界没有产生系统性偏差
  验收：典型矩形/凹多边形/水平边场景下体积结果与预期一致
- [x] 为 `VolumeCalculator` 边界点归属补充回归测试，并显式将边界点视为 polygon 内部
- [x] 收口 `FusionSegmentService` 与测量/持久化的正式集成
  范围：`Application.cpp`、体积记录持久化、历史记录/盘存消费链
  已完成：`Application.cpp` 现已通过 `FusionSegmentService::measurementCloudReady -> persistFusionMeasurementCloud(...)` 正式接入盘存主链，提交后的 `measurement cloud` 会按料堆 ROI 计算体积，并同步回写 `PileManager`、`VolumeRecord` 和 `MaterialHistoryManager`
  已验证：`frontend/tests/monitor-stream-contract.test.mjs` 已断言 `measurementCloudReady` 的持久化接线，`rtk npm --prefix frontend test` 已在 2026-04-18 全量通过
- [x] 清理 `fusion preview` 的兼容透传语义
  范围：`Application.cpp`、`WebSocketServer.cpp`
  已完成：`WebSocketServer` 现通过 `setFusionSegmentService()` 直接监听 `fusionPreviewReady`，保留独立的 `fusionPreviewMeta / fusionPreviewChunk / fusionPreviewAck` 事件链；`onGlobalMapUpdated()` 不再顺手转发 `fusionPreview`
  已验证：`frontend/tests/monitor-stream-contract.test.mjs` 已新增“不再 piggyback globalMap”断言，并在 2026-04-18 通过
- [x] 在 ARM 可运行环境执行新的 backend regression tests
  范围：`GrabSystemRegressionTests`
  已完成：2026-04-18 已通过可达编译地址 `jamin@192.168.110.128` 在测试机 `root@100.105.175.44` 成功执行 `rtk bash scripts/arm/run_backend_regression.sh`
  已补充：`scripts/arm/run_backend_regression.sh` 现会同步 `backend/include/service/WebSocketServer.h` 与 `backend/src/service/WebSocketServer.cpp`，避免 `fusion preview` 契约回归因测试机临时源码根缺文件而误失败
  已验证：脚本回执为 `[PASS] backend_regression: sha256=423e79fbe639a1509162b7c6ab6de77ea52033a7fb2022abc81bc0011a5dde1a result='All regression checks passed'`
- [x] 确认未跟踪目录的用途并决定去留
  路径：
  - `.claude/`
  - `deer-flow/`
  已处理：`.claude/` 为本地代理配置目录，已加入 `.gitignore`
  已核实：`deer-flow/` 当前工作区不存在，无需纳入主仓库
- [x] 加固 `scripts/arm/verify_remote.sh` 的摘要提取
  范围：`scripts/arm/verify_remote.sh`
  已处理：远端 verify 输出改为显式 `service/sha/index/hls/ptz/radar` key-value 行，日志回读改为按 key 解析，不再依赖固定行号。
  验证：新增 `frontend/tests/arm-verify-remote-contract.test.mjs`，并确认 `HEAD` 旧版本仍存在固定行号解析，当前工作区脚本已切到 key-value 方案。
  结果：`ptz` / `radar` 日志缺失时不会再把后续字段串位成假阳性摘要；脚本会因空值断言失败，而不是打印错位的 `PASS` 摘要。
