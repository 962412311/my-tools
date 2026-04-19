# 30-git

## 目的
本文件定义 Git 相关的默认规则，确保版本管理清晰、可追踪、不过度噪音。

---

## 基本规则
- commit message 使用英文
- commit message 简洁描述变更意图
- 默认不自动执行 `git push`
- `git push` 仅在用户明确要求时执行
- 不把 Git 提交当作垃圾桶

---

## commit message 原则
推荐做到：
- 动词明确
- 说明本次改动意图
- 只描述这次提交真实包含的内容

示例：
- `fix login state sync bug`
- `refactor settings page form logic`
- `add release checklist`
- `update knowledge base naming rules`

避免：
- `update`
- `fix stuff`
- `final`
- `misc changes`

---

## 提交前检查
准备提交前，至少确认：
- 改动是否最小必要
- 是否混入无关文件
- 是否包含敏感信息
- 是否完成基本验证
- 是否需要同步更新文档

---

## 提交粒度
默认原则：
- 一个提交表达一个清晰意图
- 不把互不相关的改动混在一起
- 修 bug、重构、文档更新尽量保持可理解边界

---

## 禁止行为
- 未验证就提交并声称完成
- 自动 push
- 把临时文件、缓存文件、敏感文件带入提交
- 用模糊 commit message 掩盖改动内容
