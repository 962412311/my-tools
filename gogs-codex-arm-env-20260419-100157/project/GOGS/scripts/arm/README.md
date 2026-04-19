# ARM Pipeline

阶段化 ARM 发布脚本，目标是把日常构建、下发、验活收敛成低噪声、强判定的固定流程。

## 设计目标

- 统一入口，减少临时拼接 `ssh` / `rsync` 命令
- 每个阶段只输出一行 `PASS/FAIL + 摘要`
- 详细日志默认下沉到 `logs/arm/`
- 成功与失败都依赖明确判定条件，而不是人工阅读长日志

## 入口

完整流水线：

```bash
bash scripts/arm/pipeline.sh
```

常用变体：

```bash
bash scripts/arm/pipeline.sh --backend-only
bash scripts/arm/pipeline.sh --frontend-only
bash scripts/arm/pipeline.sh --skip-preflight
bash scripts/arm/pipeline.sh --skip-build-frontend
```

## 阶段

- `preflight.sh`
  - 检查工作区是否干净
  - 检查 compile/test 主机是否可达
- `build_backend_remote.sh`
  - 同步当前源码到编译机
  - 不依赖编译机 `git pull origin master`
  - 删除旧 `GrabSystem`
  - 运行 `onebuild_GOGS_backend_self.sh`
  - 输出新产物 sha
- `deploy_backend.sh`
  - 取回编译产物
  - 上传测试机 `/tmp/GrabSystem.arm.new`
  - 同步 Tanway 官方 `algo_table.json` / `lidar_config.json` 到 `/userdata/GOGS/backend/config`
  - 停服务、备份、清日志、覆盖、启动
  - 判定运行中二进制 sha 与构建产物一致
- `deploy_frontend.sh`
  - 本地构建前端
  - 同步到 `/userdata/GOGS/frontend/dist`
  - 同步到 `/userdata/GOGS/backend/web`
  - reload nginx
  - 可通过 `SKIP_BUILD_FRONTEND=1` 复用现有 `frontend/dist`
- `verify_remote.sh`
  - 校验服务状态
  - 校验运行中二进制 sha
  - 校验线上首页 `index-*.js`
  - 校验 HLS `m3u8`
  - 校验最近雷达 callback
  - 输出最近 PTZ ONVIF 就绪日志摘要；若最近窗口未命中则记为 `not-observed-in-recent-journal-window`，不单独让 `core` 误失败
- `run_backend_regression.sh`
  - 从编译机取回 ARM `GrabSystemRegressionTests`
  - 同步当前源码到测试机临时目录，并为每轮生成独立的测试二进制路径
  - 在测试机设置 `GOGS_REPO_ROOT` 后执行 regression tests
  - 自带超时保护和退出清理，避免上一轮残留进程把下一轮卡死
  - 输出测试二进制 sha 与最终结果摘要
- `verify_video_workflow.sh`
  - 通过受保护 API 登录测试机后端
  - 校验 `PTZ` 就绪、抓图返回、录像启动/停止后的健康状态
  - 校验最新录像样本可被 `ffprobe` 正常识别
  - 校验 `video-files/stream` 和 `video-files/download` 回放链路
  - 输出视频专项验收摘要
- `verify_browser_matrix_readiness.sh`
  - 通过受保护 API 登录测试机后端
  - 校验 `stream-info / self-check / recording-status` 已具备真实浏览器验收前置条件
  - 读取运行态 `config.ini`，固化主/子码流分辨率、帧率、编码和录像输入编码基线
  - 输出真实浏览器应使用的 `monitor / HLS / WebRTC player` 地址与矩阵模板入口
- `generate_field_acceptance_report.sh`
  - 顺序执行 `verify_browser_matrix_readiness.sh` 与 `verify_field_acceptance_bundle.sh`
  - 生成当前 ARM 现场验收的 markdown 汇总报告
  - 把自动化已确认结论、日志路径和剩余现场动作写成一份固定证据文件
  - 同时刷新稳定路径 `logs/arm/latest-field-acceptance-report.md`
- `generate_remaining_acceptance_workpack.sh`
  - 顺序执行 `verify_browser_matrix_readiness.sh`、`verify_scale_protocol.sh`、`verify_blind_zone_workflow.sh`
  - 为浏览器矩阵、称重协议、盲区补偿三项剩余待办生成可直接回写的预填草稿
  - 每次生成时间戳工作包目录，并同步刷新稳定目录 `logs/arm/latest-remaining-acceptance-workpack/`
- `ensure_current_acceptance_packet.sh`
  - 把浏览器矩阵、称重协议、盲区补偿和现场联调记录收敛到稳定目录 `DOC/当前现场验收包/`
  - 默认只为缺失文件补种，不覆盖现场已填写内容
  - 可通过 `--refresh` 用最新工作包重新初始化浏览器/称重/盲区三份记录
- `verify_remaining_acceptance_closure.sh`
  - 先确保 `DOC/当前现场验收包/` 已存在，再校验浏览器矩阵、现场联调记录、称重记录、盲区记录、`V1.1` 清单和 `todo` 是否已经真正收口
  - 不只检查“是否填了内容”，还会检查 `是否通过/是否已同步回写` 是否为肯定态，以及浏览器矩阵、当前验收包、现场联调记录三处关键允许清单是否一致
  - 在现场文档还未填完时返回明确 `pending:*` 阻塞摘要
  - 全部填完后，作为“项目可正式关单”的最终机器校验门槛
- `finalize_remaining_acceptance_closure.sh`
  - 先重新执行 `verify_remaining_acceptance_closure.sh`，只有在 closure gate 通过后才继续
  - 把 `DOC/当前现场验收包/` 归档到 `DOC/现场验收归档/<timestamp>-remaining-acceptance-closure/`
  - 同时把 `logs/arm/latest-field-acceptance-report.md`、`logs/arm/latest-remaining-acceptance-workpack/` 和 closure gate 日志纳入正式证据归档
  - 自动把 `V1.1` 清单改为 `已通过`、把 `todo.md` 改为 `当前无剩余待办`，并更新 `DOC/项目完成状态说明.md`
  - 生成正式关单报告并刷新稳定路径 `logs/arm/latest-remaining-acceptance-closure-report.md`
- `verify_scale_protocol.sh`
  - 通过受保护 API 登录测试机后端
  - 校验 `/api/scales/status` 的设备清单、在线状态、采样新鲜度和关键配置字段
  - 支持通过 `SCALE_VERIFY_EXPECTED_SPEC` 附加期望寄存器映射进行字段级对照
  - 输出称重协议专项验收摘要
- `verify_blind_zone_workflow.sh`
  - 通过受保护 API 登录测试机后端
  - 校验盲区补偿配置键和 `/api/rescan/status` / `/api/rescan/analyze` 返回结构
  - 采样 `support / coverage / density / radius` 指标并输出慢速扫描专项摘要
  - 可通过环境变量决定是否对低支撑率直接判失败
- `verify_field_acceptance_bundle.sh`
  - 顺序执行 `verify_remote / verify_video_workflow / verify_scale_protocol / verify_blind_zone_workflow`
  - 核心软件链路异常时直接失败
  - 对 `ui/scale_devices is empty`、`processing diagnostics are not ready` 这类现场未就绪项收敛成 `blocked` 摘要
  - 输出“软件 ready / 现场 pending” 的总验收摘要

## 输出规则

主输出示例：

```text
[PASS] preflight: branch=master commit=356637e hosts=reachable
[PASS] build_backend: sha256=b918... artifact=/home/jamin/.../GrabSystem
[PASS] deploy_backend: service=active runtime_sha=b918...
[PASS] deploy_frontend: index=assets/index-BHYbzhXO.js
[PASS] verify: service=active sha=b918... index=assets/index-BHYbzhXO.js hls=#EXTM3U ptz='not-observed-in-recent-journal-window' radar='...point cloud callback...'
[PASS] verify_video_workflow: ptz='ready onvif=True wssec=True' snapshot='image/jpeg:244566' recording='healthy file=005943-00000.mp4 mode=splitmuxsink-segment'
[PASS] verify_browser_matrix_readiness: stream='path=camera api=1 hls=1 webrtc=1 sync=1 ...' self_check='ok:视频链路自检通过 ...' recording='healthy:录像链路就绪 input=auto' baseline='main=2k/20/auto sub=720p/15/h264 record=auto'
[PASS] generate_field_acceptance_report: report=/.../logs/arm/...-field-acceptance-report.md browser_status=pass bundle_status=pass
[PASS] generate_remaining_acceptance_workpack: dir=/.../logs/arm/...-remaining-acceptance-workpack latest=/.../logs/arm/latest-remaining-acceptance-workpack browser_status=pass scale_status=fail blind_status=fail
[PASS] ensure_current_acceptance_packet: packet=/.../DOC/当前现场验收包 refresh=0 seeded=4 kept=0
[FAIL] verify_remaining_acceptance_closure: remaining acceptance closure is not ready
[PASS] finalize_remaining_acceptance_closure: archive='/.../DOC/现场验收归档/...-remaining-acceptance-closure' report='/.../logs/arm/...-remaining-acceptance-closure-report.md' latest_report='/.../logs/arm/latest-remaining-acceptance-closure-report.md' v11='passed' todo='cleared'
[PASS] verify_scale_protocol: driver='status=running online=1/1/1' expected='matched' devices=1 updates='...->...' message='独立称重设备采集正常'
[PASS] verify_blind_zone_workflow: config='annulus=3.00 quantile=0.25 phase=analysis_only state=ready/not_started' metrics='support[min=0.420,avg=0.455,max=0.481] ...'
[PASS] verify_field_acceptance_bundle: core='[PASS] verify: ...' video='[PASS] verify_video_workflow: ...' scale='blocked: ui/scale_devices empty' blind='blocked: processing diagnostics not ready'
```

详细日志位置：

```text
logs/arm/
```

失败时只回显：

- 阶段名
- 日志文件路径
- 日志尾部少量关键行

## 约束

- `preflight.sh` 默认要求工作区干净；如果当前只是验证脚本行为，可显式使用 `--skip-preflight`
- 不自动执行 `git add/commit/push`
- 运行目标来自：
  - `.codex/skills/arm-crosscompile-test/references/runtime-targets.local.yml`

## 后续可继续增强

- `verify_remote.sh` 增加 PTZ 与视频 API 摘要
- `generate_field_acceptance_report.sh` 继续扩展现场模板回填提示或附加证据链接
- `generate_remaining_acceptance_workpack.sh` 继续扩展对称重/盲区运行态的自动预填深度
- `finalize_remaining_acceptance_closure.sh` 后续可继续扩展为“自动校验最终归档是否已同步到更多对外交付物和外部交付介质”
- `verify_browser_matrix_readiness.sh` 继续扩展真实浏览器地址探针或批量现场回写辅助
- `verify_video_workflow.sh` 继续扩展长时录像场景
- `verify_scale_protocol.sh` 继续支持样本称重点偏差和异常码实测比对
- `verify_blind_zone_workflow.sh` 继续支持参数矩阵批量扫描和趋势判定
- `deploy_frontend.sh` 支持跳过本地重建，仅同步现有 `dist`
- `build_backend_remote.sh` 增加“编译 warning 摘要计数”而不是只记录完整日志
