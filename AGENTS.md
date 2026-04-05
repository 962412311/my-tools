# Repository Maintenance Notes

这个仓库用于维护个人可复用工具脚本。

约定：

- 新增脚本优先按能力域放到 `scripts/` 下
- 说明文档同步更新到 `README.md`
- 不要把任何明文密钥、令牌、密码写进仓库文件
- Git 登录建议使用本机的 credential helper 管理，不要把凭据固化进文档
- 提交信息尽量短而明确，方便后续按脚本分类回溯

当前重点脚本：

- `scripts/sysroot/repair_sysroot_paths.py`
