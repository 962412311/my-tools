# Scripts Index

这里按能力域维护脚本索引。新增工具时，优先在对应子目录补充 README，再把条目挂到这里。

## Sysroot

- [sysroot/repair_sysroot_paths.py](sysroot/repair_sysroot_paths.py)
  - 修复 sysroot 中泄露的绝对路径、重复前缀，以及常见绝对符号链接问题

## Launcher

- [start.sh](start.sh)
  - 一键启动应用，可通过脚本内部变量配置应用名称、`/userdata` 下的目录名、Qt 运行库路径和是否自动全屏

## Claude

- [claude/rate_limit_auto_continue/README.md](claude/rate_limit_auto_continue/README.md)
  - Claude 触发 `StopFailure` 后自动解析限额重置时间，并在到点后自动输入“继续”并回车
- [claude/rate_limit_auto_continue/CONTRACT.md](claude/rate_limit_auto_continue/CONTRACT.md)
  - 给后续 Agent 的跨平台实现契约，定义目标、流程、验收标准和平台边界
- [claude/arm_crosscompile_test/README.md](claude/arm_crosscompile_test/README.md)
  - 当前项目 ARM 交叉编译、部署和测试 skill 的归档版本，包含本地配置索引
- [claude/claude_api/README.md](claude/claude_api/README.md)
  - Claude API skill 归档，包含修正后的 frontmatter 与原始 skill 正文

## 目录建议

- `scripts/sysroot/`：sysroot、SDK、交叉编译相关修复工具
- `scripts/git/`：git 仓库辅助脚本
- `scripts/devops/`：部署、同步、维护类脚本
- `scripts/dev/`：本地开发辅助脚本
- `scripts/claude/`：Claude hooks、自动化和配套工具
- `scripts/claude/arm_crosscompile_test/`：当前项目 ARM 交叉编译、部署和测试 skill 归档
