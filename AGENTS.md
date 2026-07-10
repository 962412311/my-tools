# Repository Maintenance Notes

这个仓库用于维护当前已验证的 Codex 初始化工具集和全局 Agent
规则树，目标是在新环境中可从 `codex-home/` 或打包产物复现
`$HOME/.codex` 里的全局 Agent 入口及其子结构。

约定：

- `codex-home/` 只放需要手动同步到 `$HOME/.codex` 的初始化文件和全局 Agent 规则文件
- `codex-home/` 应按当前 `$HOME/.codex` 的 Agent 文件树原样同步，不额外改写路径
- `codex-home/global-rules/` 归档当前全局规则树
- `codex-home/vendor_imports/` 只归档全局 Agent 规则链明确依赖的公开 vendor import，不归档其 `.git/`
- `scripts/codex-agent-tree/` 维护打包和白名单覆盖部署脚本
- 部署脚本必须兼容 macOS 自带 `/bin/sh`、BSD `tar`、BSD `mktemp`、系统 `rsync` 和 `shasum`；不要引入 GNU-only 参数
- `codex-launcher/codex` 必须同时兼容 macOS 与 WSL/Linux；用户 HOME 解析不得硬编码 `/Users` 或 `/home`，平台专用命令必须有对应分支或回退
- `docs/codex-skill-scope.md` 只记录裁剪后的 skill 范围，不备份 skill 内容
- 官方自带 `.system` skills 不纳入仓库
- 自动安装或自动更新的 skill/plugin 目录不纳入仓库
- 私有项目 skills、会话、记忆、缓存、shell snapshots、数据库状态、本机 trust 配置不纳入仓库
- 不要把任何明文密钥、令牌、密码写进仓库文件
- Git 登录建议使用本机的 credential helper 管理，不要把凭据固化进文档
- 提交信息尽量短而明确，方便后续按 Codex 初始化文件回溯

修改 `codex-home/` 下文件时，应先和当前 `$HOME/.codex` 对应文件对比，确认这是经过验证的有效配置。
