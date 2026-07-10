# Codex Tooling

这个仓库用于归档和部署当前 `$HOME/.codex` 的全局 Agent 规则树，不是完整的 Codex 运行态备份。

## 内容

- `codex-home/`：可部署到 `$HOME/.codex` 的 Agent 文件树，按当前全局配置原样镜像
- `codex-home/path.sh`：Codex 启动 PATH 脚本
- `codex-launcher/codex`：安装到 `$HOME/.local/bin/codex` 的完整启动 wrapper
- `codex-home/global-rules/`：按任务类型拆分的全局规则
- `codex-home/vendor_imports/andrej-karpathy-skills/`：全局规则链依赖的公开 vendor import，排除 `.git/`
- `scripts/codex-agent-tree/package.sh`：生成部署包
- `scripts/codex-agent-tree/deploy.sh`：部署 `.codex` 文件树和启动 wrapper
- `dist/codex-global-agent-tree.tar.gz`：当前已生成的部署包

## 完整部署

1. 克隆仓库：

```bash
git clone https://github.com/962412311/my-tools.git
cd my-tools
```

2. 生成部署包：

```bash
scripts/codex-agent-tree/package.sh
```

3. 部署到当前用户：

```bash
scripts/codex-agent-tree/deploy.sh --archive dist/codex-global-agent-tree.tar.gz
```

4. 如需部署到指定目录：

```bash
scripts/codex-agent-tree/deploy.sh \
  --archive dist/codex-global-agent-tree.tar.gz \
  --target /path/to/.codex \
  --launcher-target /path/to/.local/bin/codex
```

## 一句话给 Codex

```text
请基于 https://github.com/962412311/my-tools.git，严格按照该 git 仓库的 README 完整部署 Codex 启动脚本和全局 Agent 结构树。
```

## Codex 启动脚本

完整启动链由两个文件组成：

- `codex-launcher/codex` 是实际命令入口，负责更新检查、插件和 skill 同步、订阅检查，并向真实 Codex 注入默认模型参数
- `codex-home/path.sh` 负责整理 `PATH` 并导出 wrapper 使用的启动参数

`codex-home/path.sh` 会：

- 加入 `$HOME/.local/bin`
- 加入 `$HOME/.codex/npm-global/bin`
- 根据当前平台选择 `@openai/codex-*` optional package 的 vendor path
- 设置默认启动模型为 `gpt-5.6-sol`
- 设置默认推理强度为 `high`
- 设置启动前远端检查重试次数为 `3`
- 设置登录 token 剩余 24 小时以内才主动刷新

默认模型可通过环境变量覆盖：

```bash
CODEX_DEFAULT_MODEL=gpt-5.6-sol CODEX_DEFAULT_REASONING_EFFORT=high codex
```

启动前网络检查参数也可通过环境变量覆盖：

```bash
CODEX_STARTUP_HTTP_ATTEMPTS=3 CODEX_TOKEN_REFRESH_MIN_SECONDS=86400 codex
```

部署后会同时覆盖 `$HOME/.codex/path.sh` 和 `$HOME/.local/bin/codex`。如果只想手动更新启动链：

```bash
mkdir -p "$HOME/.local/bin"
cp codex-launcher/codex "$HOME/.local/bin/codex"
chmod 0755 "$HOME/.local/bin/codex"
cp codex-home/path.sh "$HOME/.codex/path.sh"
```

## 部署边界

部署脚本只覆盖：

- `AGENTS.md`
- `BOOTSTRAP.md`
- `GLOBAL-AGENT.md`
- `KARPATHY-INTEGRATION.md`
- `RTK.md`
- `path.sh`
- `global-rules/`
- `vendor_imports/andrej-karpathy-skills/`
- `$HOME/.local/bin/codex`

不会覆盖或删除：

- `auth.json`
- `config.toml`
- `state*.sqlite*`
- `sessions/`
- `memories/`
- `cache/`
- `plugins/`
- `log/`

## macOS 与 WSL/Linux

同一套归档和启动 wrapper 支持 macOS 与 WSL/Linux：

- macOS 使用 `dscl` 解析用户 HOME，并兼容系统 `/bin/sh`、BSD `tar`、BSD `mktemp`、系统 `rsync` 和 `shasum`
- WSL/Linux 使用 `getent passwd` 解析用户 HOME，并支持 Linux x86_64 / arm64 Codex optional package 路径
- `codex-home/path.sh` 可被 zsh 或 Bash source，不切换调用方 shell 的解析模式
- `codex-launcher/codex` 使用 Bash；平台专用的可选功能缺失时会跳过，不阻断 Codex 启动

打包和解包时使用 `COPYFILE_DISABLE=1`，避免 macOS AppleDouble 元数据进入归档。
