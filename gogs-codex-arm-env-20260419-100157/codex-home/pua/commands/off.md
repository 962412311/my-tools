---
description: "PUA 关闭默认模式 — 关闭自动加载和反馈收集。/pua:off。Triggers on: '/pua:off', 'pua off', '关闭pua', 'disable pua', 'always off'."
---

关闭 PUA 默认模式：

1. 确保 `~/.pua/` 目录存在
2. 将 `{"always_on": false, "feedback_frequency": 0}` 写入 `~/.pua/config.json`
3. 输出确认：> [PUA OFF] PUA 默认模式和反馈收集已关闭。需要时手动 /pua:pua 触发。
