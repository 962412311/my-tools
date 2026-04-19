# GOGS 当前剩余待办

状态说明、现场已确认事实和历史完成事项不再写在本文件。

参考文档：

- [系统成熟化实施计划](DOC/系统成熟化实施计划.md)
- [项目完成状态说明](DOC/项目完成状态说明.md)
- [历史已完成事项归档](DOC/todo历史已完成归档.md)
- [ARM Field Notes](.codex/skills/arm-crosscompile-test/references/field-notes.md)
- 当前自动化现场摘要入口：`rtk bash scripts/arm/verify_field_acceptance_bundle.sh`
- 当前剩余现场预填工作包入口：`rtk bash scripts/arm/generate_remaining_acceptance_workpack.sh`
- 当前稳定现场回写包入口：`rtk bash scripts/arm/ensure_current_acceptance_packet.sh`
- 当前最终现场收口校验入口：`rtk bash scripts/arm/verify_remaining_acceptance_closure.sh`
- 当前最终现场关单入口：`rtk bash scripts/arm/finalize_remaining_acceptance_closure.sh`

## 剩余待办

1. 真实浏览器兼容矩阵与允许清单
   - 先运行 `rtk bash scripts/arm/verify_browser_matrix_readiness.sh`，固定当前运行态的 `monitor / HLS / WebRTC player` 地址、主/子码流编码和录像输入编码基线。
   - 再在有显示输出的真实浏览器/终端上完成 `WebRTC/HLS × H.264/H.265` 实测，不接受仅凭 headless 浏览器或接口状态下结论。
   - 需要回写：
     - `DOC/当前现场验收包/视频实机验收矩阵.md`
     - `DOC/视频浏览器兼容矩阵.md`
     - `DOC/V1.1视频链路版本化验收清单.md`
   - 目标结论：
     - 哪些浏览器允许直放 `H.265`
     - 哪些浏览器必须切回 `H.264`
     - 哪些浏览器需要强制降级到 `HLS`

2. 真实称重设备协议核对
   - 按 `rtk bash scripts/arm/verify_scale_protocol.sh` + `DOC/称重设备现场协议核对SOP.md` 在真实称重设备上核对寄存器映射、心跳周期、重量换算系数和异常码语义。
   - 需要回写 `DOC/当前现场验收包/称重设备协议验收记录.md`、最终参数口径和相关 README。

3. 真实料堆慢速扫描盲区补偿参数验证
   - 按 `rtk bash scripts/arm/verify_blind_zone_workflow.sh` + `DOC/点云盲区补偿慢速扫描验收标准.md` 在真实慢速扫描场景验证盲区补偿参数、补扫触发阈值和结果稳定性。
   - 需要回写 `DOC/当前现场验收包/盲区补偿参数试验记录.md`、算法诊断文档和最终推荐参数。

4. `V1.1` 视频链路最终版本化验收收口
   - 前置条件：第 1、2、3 项已完成并已回写到 `DOC/当前现场验收包/`。
   - 输出物：
     - 一份已填写的实机矩阵
     - 一份已填写的现场联调验收记录
     - `V1.1` 视频链路版本化验收清单状态改为“已通过”
     - 最后执行 `rtk bash scripts/arm/finalize_remaining_acceptance_closure.sh`，把当前验收包归档并把 `todo.md` 收口为“当前无剩余待办”

## 维护规则

- 历史已完成事项只维护在 [DOC/todo历史已完成归档.md](DOC/todo历史已完成归档.md)。
- 每次推进剩余项，都要同时更新实现、验证记录、相关文档和本清单。
- 任何 ARM 构建或发布动作都只能通过编译机完成，不允许在测试机本地编译。
