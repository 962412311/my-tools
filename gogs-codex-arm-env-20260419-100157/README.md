# GOGS Codex ARM Environment Archive

## 概述

这份归档用于在另一台电脑上快速恢复当前 `GOGS` 项目的 ARM 开发辅助环境，重点保留：

- 当前会话正在使用的项目级 `arm` skill 与项目知识
- `~/.codex` 下与 Codex 工作流直接相关的全局配置
- 当前会话里的 `AGENTS.md` 指令快照

## 目录结构

- `codex-home/`
  - 准备恢复到目标机器 `~/.codex/`
  - 已包含：`GLOBAL-AGENT.md`、`RTK.md`、`AGENTS.md`、`config.toml`、`global-rules/`、`skills/`、`superpowers/`、`pua/`、`prompts/`
- `project/GOGS/`
  - 项目侧规则与资料覆盖层，不是完整源码仓库
  - 已包含：`.codex/`、`scripts/`、`DOC/`、`docs/`、`frontend/docs/`、`deploy/systemd/`、`lib/arm/`、`README.md`、`todo.md`、`logs/arm/latest-*`
- `session-snapshots/`
  - 当前会话提到但仓库内未实际落盘的快照文件

## 明确包含

- 全局 `GLOBAL` 规则本体：
  - `codex-home/GLOBAL-AGENT.md`
  - `codex-home/global-rules/`
- ARM 相关 skill：
  - `codex-home/skills/arm_crosscompile_test/`
  - `project/GOGS/.codex/skills/arm-crosscompile-test/`
- 项目侧 ARM 流程与现场资料：
  - `project/GOGS/scripts/arm/`
  - `project/GOGS/DOC/`
  - `project/GOGS/docs/`
  - `project/GOGS/logs/arm/latest-field-acceptance-report.md`
  - `project/GOGS/logs/arm/latest-remaining-acceptance-workpack/`

## 明确未包含

- `~/.codex/auth.json`
- `~/.codex/cache/`
- `~/.codex/log/`
- `~/.codex/logs_2.sqlite*`
- `~/.codex/memories/`
- `~/.codex/sessions/`
- 当前项目完整源码与 `.git/`

这些内容要么包含敏感凭据，要么属于缓存/日志/状态文件，不适合上传迁移。目标机器需要你自行登录 Codex，并另外准备完整项目源码仓库。

## 恢复方式

### 1. 恢复 Codex 全局环境

```bash
bash restore.sh --codex-home "$HOME/.codex"
```

### 2. 覆盖到目标 GOGS 仓库

先在目标机器准备一份 `GOGS` 仓库源码，再执行：

```bash
bash restore.sh --project-root "/path/to/GOGS"
```

### 3. 一次性同时恢复

```bash
bash restore.sh --codex-home "$HOME/.codex" --project-root "/path/to/GOGS"
```

## 备注

- `project/GOGS/AGENTS.md` 是根据当前会话中的 `AGENTS.md` 指令重建的快照，便于另一台机器直接恢复相同入口规则。
- 恢复脚本默认覆盖同名文件；如目标目录内已有你不想丢失的本地改动，先自行备份。
