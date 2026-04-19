# ARM Remaining Acceptance Workpack

- Generated At: 2026-04-19T08:58:25+08:00
- Target Host: 100.105.175.44
- Workpack Dir: /mnt/d/QtWorkData/GOGS/logs/arm/20260419-085804-remaining-acceptance-workpack
- Latest Stable Dir: /mnt/d/QtWorkData/GOGS/logs/arm/latest-remaining-acceptance-workpack
- Current Acceptance Packet: /mnt/d/QtWorkData/GOGS/DOC/当前现场验收包

## 包含内容

- 浏览器矩阵草稿：/mnt/d/QtWorkData/GOGS/logs/arm/20260419-085804-remaining-acceptance-workpack/browser-matrix.md （status=pass）
- 称重协议草稿：/mnt/d/QtWorkData/GOGS/logs/arm/20260419-085804-remaining-acceptance-workpack/scale-protocol.md （status=fail）
- 盲区补偿草稿：/mnt/d/QtWorkData/GOGS/logs/arm/20260419-085804-remaining-acceptance-workpack/blind-zone-workflow.md （status=fail）

## 当前自动化摘要

- 浏览器矩阵准备：[PASS] verify_browser_matrix_readiness: stream='path=camera api=1 hls=1 webrtc=1 sync=1 lastError=none' self_check='ok:视频链路自检通过 items=stream:ok,recording:ok,ptz:ok,snapshot:ok' recording='healthy:录像链路就绪 input=h264' baseline='main=2k/20/auto sub=720p/15/h264 record=h264' urls='monitor=http://100.105.175.44/monitor hls=http://100.105.175.44/media/hls/camera/index.m3u8 webrtc=http://100.105.175.44/media/webrtc/camera/'
- 称重协议：[FAIL] verify_scale_protocol: scale protocol verification failed log: /mnt/d/QtWorkData/GOGS/logs/arm/20260419-085811-verify-scale-protocol.log Traceback (most recent call last): File "<stdin>", line 102, in <module> RuntimeError: scale devices are not configured on target host (ui/scale_devices is empty)
- 盲区补偿：[FAIL] verify_blind_zone_workflow: blind-zone workflow verification failed log: /mnt/d/QtWorkData/GOGS/logs/arm/20260419-085818-verify-blind-zone-workflow.log Traceback (most recent call last): File "<stdin>", line 127, in <module> RuntimeError: processing diagnostics are not ready: blind-zone metrics are unavailable, confirm live point-cloud processing first

## 现场使用顺序

1. 先在浏览器草稿里完成真实终端的 WebRTC/HLS × H.264/H.265 矩阵。
2. 称重设备到位后，按称重草稿补寄存器映射、三点实称和异常码。
3. 慢速扫描场景形成活跃诊断后，按盲区草稿补参数矩阵和现场结论。
4. 三份草稿回写正式文档后，再更新 todo 与版本化验收状态。
5. 最后运行 rtk bash scripts/arm/verify_remaining_acceptance_closure.sh，确认项目已经满足正式关单门槛。
6. 如果第 5 步返回 PASS，再运行 rtk bash scripts/arm/finalize_remaining_acceptance_closure.sh，生成正式归档并关闭 todo。

## 日志

- 浏览器阶段日志：/mnt/d/QtWorkData/GOGS/logs/arm/20260419-085804-browser.workpack-stage.log
- 浏览器详情日志：/mnt/d/QtWorkData/GOGS/logs/arm/20260419-085804-verify-browser-matrix-readiness.log
- 称重阶段日志：/mnt/d/QtWorkData/GOGS/logs/arm/20260419-085804-scale.workpack-stage.log
- 称重详情日志：/mnt/d/QtWorkData/GOGS/logs/arm/20260419-085811-verify-scale-protocol.log
- 盲区阶段日志：/mnt/d/QtWorkData/GOGS/logs/arm/20260419-085804-blind.workpack-stage.log
- 盲区详情日志：/mnt/d/QtWorkData/GOGS/logs/arm/20260419-085818-verify-blind-zone-workflow.log
- 汇总日志：/mnt/d/QtWorkData/GOGS/logs/arm/20260419-085804-generate-remaining-acceptance-workpack.log
- 当前现场验收包同步日志：/mnt/d/QtWorkData/GOGS/logs/arm/20260419-085804-ensure-current-acceptance-packet.from-workpack.log
