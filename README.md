# My Tools

这个仓库维护我日常可复用的工具脚本，目标是把零散脚本统一收纳、说明清楚、便于扩展。

## 目录

- [scripts/README.md](scripts/README.md)：脚本总索引
- [AGENTS.md](AGENTS.md)：仓库维护约定

## 当前工具

- [scripts/sysroot/repair_sysroot_paths.py](scripts/sysroot/repair_sysroot_paths.py)：修复 sysroot 中泄露的绝对路径、重复前缀，以及常见绝对符号链接问题
- [scripts/start.sh](scripts/start.sh)：基于脚本内部变量的一键启动器，可配置应用名称、应用目录和是否全屏
- [scripts/claude/rate_limit_auto_continue/](scripts/claude/rate_limit_auto_continue/README.md)：Claude 限额后自动继续的 hook、后台 worker 和安装说明
- [scripts/claude/arm_crosscompile_test/](scripts/claude/arm_crosscompile_test/README.md)：当前项目 ARM 交叉编译、部署和测试 skill 归档

## 使用方式

先看脚本对应的索引说明，再根据参数直接执行。大多数脚本都支持 `--help`。

```bash
python3 scripts/sysroot/repair_sysroot_paths.py --help
python3 scripts/sysroot/repair_sysroot_paths.py --sysroot /opt/sysroot/binary --dry-run
python3 scripts/sysroot/repair_sysroot_paths.py --sysroot /opt/sysroot/binary
./scripts/start.sh
./scripts/claude/rate_limit_auto_continue/install.sh
```

## 维护原则

- 新工具按能力域放到 `scripts/` 下
- 每个脚本都要补一段用途、示例和注意事项
- 说明优先写在脚本索引里，README 只保留仓库级概览
- 不写入任何明文密钥、令牌、密码
