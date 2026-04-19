# 现场验收归档

这个目录只保存已经完成正式关单的现场验收记录快照。

当前使用规则：

1. 现场填写统一先落到 [`DOC/当前现场验收包/`](../当前现场验收包/README.md)。
2. 先执行 `rtk bash scripts/arm/verify_remaining_acceptance_closure.sh`，确认现场回写已满足正式关单门槛。
3. 再执行 `rtk bash scripts/arm/finalize_remaining_acceptance_closure.sh`，把当前验收包归档成时间戳正式记录。

归档内容会包含：

- 当前现场验收包四份正式回写记录
- `logs/arm/latest-field-acceptance-report.md` 对应的自动化现场摘要快照
- `logs/arm/latest-remaining-acceptance-workpack/` 对应的最近预填工作包快照
- `verify_remaining_acceptance_closure.sh` 的最终通过日志
- `DOC/视频浏览器兼容矩阵.md` 最终版本
- `DOC/V1.1视频链路版本化验收清单.md` 最终版本
- `DOC/项目完成状态说明.md` 最终版本
- `todo.md` 关单后版本
