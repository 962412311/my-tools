# Scripts Index

这里按能力域维护脚本索引。新增工具时，优先在对应子目录补充 README，再把条目挂到这里。

## Sysroot

- [sysroot/repair_sysroot_paths.py](sysroot/repair_sysroot_paths.py)
  - 修复 sysroot 中泄露的绝对路径、重复前缀，以及常见绝对符号链接问题

## Launcher

- [start.sh](start.sh)
  - 一键启动应用，可通过脚本内部变量配置应用名称、`/userdata` 下的目录名、Qt 运行库路径和是否自动全屏

## 目录建议

- `scripts/sysroot/`：sysroot、SDK、交叉编译相关修复工具
- `scripts/git/`：git 仓库辅助脚本
- `scripts/devops/`：部署、同步、维护类脚本
- `scripts/dev/`：本地开发辅助脚本
