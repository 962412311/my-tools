# ARM Field Acceptance Report

- Generated At: 2026-04-19T08:58:04+08:00
- Browser Readiness Status: pass
- Field Bundle Status: pass

## 当前自动化结论

- 浏览器矩阵准备：[PASS] verify_browser_matrix_readiness: stream='path=camera api=1 hls=1 webrtc=1 sync=1 lastError=none' self_check='ok:视频链路自检通过 items=stream:ok,recording:ok,ptz:ok,snapshot:ok' recording='healthy:录像链路就绪 input=h264' baseline='main=2k/20/auto sub=720p/15/h264 record=h264' urls='monitor=http://100.105.175.44/monitor hls=http://100.105.175.44/media/hls/camera/index.m3u8 webrtc=http://100.105.175.44/media/webrtc/camera/'
- 现场总验收：[PASS] verify_field_acceptance_bundle: core='[PASS] verify: service=active sha=5ef7aba908e780d3cac5527dd4445f5cdb81b4a2b0ccf1942356ad918c836104 index=assets/index-Bxrnerc2.js hls=#EXTM3U ptz='not-observed-in-recent-journal-window' radar='Apr 19 08:57:30 linaro-alip bash[972384]: [2026-04-19 08:57:30.953] [INFO] Tanway SDK point cloud callback #68429 points=354367 minAngle=0.10 maxAngle=359.88 span=359.78'' video='[PASS] verify_video_workflow: ptz='ready onvif=True wssec=True' snapshot='image/jpeg:463214' recording='healthy file=085738-00000.mp4 mode=splitmuxsink-segment' ffprobe='h264:2560x1440:9.378000' stream='206:1024' download='200:1107285'' scale='blocked: ui/scale_devices empty' blind='blocked: processing diagnostics not ready'

## 日志与证据

- Latest 报告：/mnt/d/QtWorkData/GOGS/logs/arm/latest-field-acceptance-report.md
- 浏览器矩阵准备日志：/mnt/d/QtWorkData/GOGS/logs/arm/20260419-085722-browser.report-stage.log
- 现场总验收日志：/mnt/d/QtWorkData/GOGS/logs/arm/20260419-085722-bundle.report-stage.log
- 汇总日志：/mnt/d/QtWorkData/GOGS/logs/arm/20260419-085722-generate-field-acceptance-report.log

## 剩余现场动作

- 在有显示输出的真实 Chrome / Edge / Firefox / Safari 终端上，根据当前 monitor / HLS / WebRTC 地址填写 `DOC/当前现场验收包/视频实机验收矩阵.md`。
- 完成 `WebRTC/HLS × H.264/H.265` 实测后，把允许直放 H.265、必须回退 H.264、必须降级 HLS 的浏览器清单回写到 `DOC/视频浏览器兼容矩阵.md`。
- 测试机当前仍无称重设备运行态配置；接入真实称重设备后，执行 `rtk bash scripts/arm/verify_scale_protocol.sh` 并回写 `DOC/当前现场验收包/称重设备协议验收记录.md`。
- 当前尚无可用于盲区补偿验收的活跃处理诊断；在真实慢速扫描场景形成诊断后，执行 `rtk bash scripts/arm/verify_blind_zone_workflow.sh` 并回写 `DOC/当前现场验收包/盲区补偿参数试验记录.md`。
- 在现场记录全部回写完成并且 closure gate 通过后，执行 `rtk bash scripts/arm/finalize_remaining_acceptance_closure.sh`，统一归档当前验收包并更新 `V1.1`、`todo.md` 与 `DOC/项目完成状态说明.md`。
