# 当前现场验收包

- Generated At: 2026-04-19T08:58:42+08:00
- Packet Dir: /mnt/d/QtWorkData/GOGS/DOC/当前现场验收包
- Refresh Mode: 0
- Browser Source: /mnt/d/QtWorkData/GOGS/logs/arm/latest-remaining-acceptance-workpack/browser-matrix.md
- Scale Source: /mnt/d/QtWorkData/GOGS/logs/arm/latest-remaining-acceptance-workpack/scale-protocol.md
- Blind Source: /mnt/d/QtWorkData/GOGS/logs/arm/latest-remaining-acceptance-workpack/blind-zone-workflow.md
- Field Source: /mnt/d/QtWorkData/GOGS/DOC/现场联调验收记录模板.md

## 使用规则

1. 在本目录内填写当前真实现场回写内容，不直接修改模板文档。
2. 若需要按最新自动化摘要重置浏览器/称重/盲区三份记录，可执行：
   - `rtk bash scripts/arm/ensure_current_acceptance_packet.sh --refresh`
3. 现场填写完成后，执行：
   - `rtk bash scripts/arm/verify_remaining_acceptance_closure.sh`
4. 如果第 3 步返回 `PASS`，再执行：
   - `rtk bash scripts/arm/finalize_remaining_acceptance_closure.sh`

## 包含文件

- `视频实机验收矩阵.md`
- `称重设备协议验收记录.md`
- `盲区补偿参数试验记录.md`
- `现场联调验收记录.md`
