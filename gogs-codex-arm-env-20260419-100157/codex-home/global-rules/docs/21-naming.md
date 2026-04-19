# 21-naming

## 目的
本文件定义目录名、文件名、文档标题的命名规则，保证内容可扫描、可搜索、可排序。

---

## 命名总原则
命名应满足：
- 见名知义
- 易于检索
- 易于排序
- 语义稳定
- 尽量长期有效

---

## 文件命名建议

### 通用格式
优先使用以下格式之一：
- `YYYY-MM-DD-topic.md`
- `project-name-overview.md`
- `feature-name-spec.md`
- `meeting-notes-YYYY-MM-DD.md`
- `decision-YYYY-MM-DD-topic.md`
- `SOP-topic.md`

### 命名要求
- 使用小写英文或稳定中英混合格式
- 用 `-` 分隔单词
- 日期统一使用 `YYYY-MM-DD`
- 同类文档使用同一模式

---

## 目录命名建议
目录名应体现清晰用途，例如：
- `specs`
- `meeting-notes`
- `sop`
- `archive`
- `research`
- `assets`

避免：
- `new`
- `temp`
- `others`
- `杂项`
- `先这样`

---

## 标题命名建议
标题应让读者快速知道：
- 主题是什么
- 文档类型是什么
- 是否与某个时间点或项目相关

例如：
- `登录流程重构方案`
- `知识库命名规范`
- `Meeting Notes - 2026-04-14`
- `SOP - 发布前检查`

---

## 禁止命名
避免：
- `新建文档.md`
- `临时整理.md`
- `想法记录2.md`
- `最终版_v7_真的最终版.md`
- 仅靠作者记忆才能理解的缩写名

---

## 版本处理建议
默认不要在文件名中反复叠加 `v2`、`v3`、`final`。优先采用：
- 稳定文件名 + 文档内更新时间
- 历史版本放归档
- 决策变更写 Decision Record
