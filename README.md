# My Tools

这是一个集中维护个人可复用工具脚本的仓库。

当前收录：

- `scripts/sysroot/repair_sysroot_paths.py`：修复 sysroot 中泄露的绝对路径、重复前缀，以及常见绝对符号链接问题。

## `scripts/sysroot/repair_sysroot_paths.py`

用途：

- 扫描指定 sysroot 下的 `cmake`、`pkgconfig`、`*.pc`、`*.la`、`*.pri` 等文本文件
- 修复诸如 `/usr/lib/...`、`/usr/include/...` 这类漏进 sysroot 的绝对路径
- 压平重复拼接出来的 sysroot 前缀
- 处理部分系统库目录下的绝对符号链接
- 可选清理指定 build 目录

示例：

```bash
python3 scripts/sysroot/repair_sysroot_paths.py --sysroot /opt/sysroot/binary --dry-run
python3 scripts/sysroot/repair_sysroot_paths.py --sysroot /opt/sysroot/binary
python3 scripts/sysroot/repair_sysroot_paths.py --sysroot /opt/sysroot/binary --clean-build /path/to/build
```

参数：

- `--sysroot`：必填，目标 sysroot 根目录
- `--dry-run`：只预览，不写回文件
- `--clean-build`：修复后可选删除指定 build 目录

注意：

- 脚本会在首次修改文件前创建备份，后缀为 `.bak_before_py_fix`
- 建议先用 `--dry-run` 确认命中范围，再执行实际修复

## 目录约定

后续新增工具脚本时，建议按能力域分组放在 `scripts/` 下，例如：

- `scripts/sysroot/`
- `scripts/git/`
- `scripts/devops/`

新增脚本后，在本文件补充对应说明和示例。
