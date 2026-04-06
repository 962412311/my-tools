# Claude Rate Limit Auto Continue

这套工具用于 Claude 触发 `StopFailure` 后，自动解析限额重置时间，在临近恢复时提示，并在到点后自动把 `继续` 粘贴到当前输入框并回车。

## 目录说明

- `rate_limit_continue.sh`：Claude hook 入口，负责读取 hook 输入、提取重置时间、去重和拉起后台 worker
- `rate_limit_continue_worker.py`：后台执行器，负责等待、通知和自动输入“继续”
- `install.sh`：把脚本安装到 `~/.claude/hooks/`，并打印推荐的 hook 配置片段
- `CONTRACT.md`：跨平台需求、流程和给后续 Agent 的实现契约

## 工作原理

1. Claude 在 `StopFailure` 事件触发时调用 `rate_limit_continue.sh`
2. 脚本从 hook 输入里提取 `last_assistant_message`、`error`、`error_details`、`reason`
3. 从文本中匹配重置时间，例如：
   - `2026-04-06 16:00:36`
   - ISO 8601 时间格式
4. 如果已经解析到重置时间，就创建锁文件，避免同一会话重复启动多个任务
5. 后台 worker 等待到重置时间前后，再额外缓冲 10 秒
6. 到点后通过 `osascript` 自动输入 `继续` 并回车

## 推荐配置

建议把 Claude 的 hook matcher 设为 `*`，让所有 `StopFailure` 都先进入脚本，再由脚本自行判断是否真的是限额类错误。

### `~/.claude/settings.json` 片段

```json
{
  "hooks": {
    "StopFailure": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/rate_limit_continue.sh",
            "async": true
          }
        ]
      }
    ]
  }
}
```

## 安装

在 `MyTools` 仓库里执行：

```bash
./scripts/claude/rate_limit_auto_continue/install.sh
```

脚本会把运行文件复制到 `~/.claude/hooks/`，并创建锁目录。安装完成后，记得重启 Claude 会话让新配置生效。

## 日志位置

- `~/.claude/hooks/rate_limit_continue.log`
- `~/.claude/hooks/.rate_limit_locks/`

## 验证方法

1. 触发一次 `StopFailure`
2. 查看日志是否出现：
   - `检测到 rate limit`
   - `已自动输入“继续”并回车`
3. 如果日志只出现第一条，说明还在等待恢复时间
4. 如果完全没有日志，说明当前会话没加载到 hook，或者没有触发 `StopFailure`

## 注意事项

- 该流程依赖 macOS 的 `osascript` 和 `System Events`
- 这套脚本不会把任何密钥写进仓库
- 如果你改了 `~/.claude/settings.json`，通常需要重启 Claude 会话才能加载新 hook

## 面向后续 Agent 的约束

如果后续要让 Codex 或 Claude 修改这套工具，先读 [CONTRACT.md](CONTRACT.md)。
那份文档只定义目标、流程、验收标准和平台边界，不规定具体输入模拟工具，方便你在 macOS、Linux、Windows 和 WSL 上分别落实现实可用的方案。
