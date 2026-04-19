---
name: stage-based-execution
description: Use when work involves repetitive multi-stage engineering or operational workflows that are noisy, error-prone, or hard to judge from raw logs, especially builds, deployments, migrations, environment changes, or remote execution chains.
---

# Stage-Based Execution

## Overview

把重复工程任务收敛成固定阶段、固定判定、固定摘要。不要靠聊天式操作和海量日志判断状态。

核心原则：

1. 阶段固定
2. 日志下沉
3. 成功强判定
4. 输出低噪声

## When to Use

适用于这类任务：

- 构建、部署、发布、验活
- 远端机器操作
- 环境修复或环境初始化
- 数据迁移、批处理、导入导出
- 任意“步骤多、输出长、容易误判成功”的工程流程

不适用于：

- 一次性的小改动
- 纯分析、纯问答
- 没有明确阶段边界的开放式研究

## Required Workflow

### 1. 先定义阶段

先把任务拆成 3 到 6 个固定阶段。每个阶段都要有：

- 输入
- 动作
- 输出
- 成功判定
- 失败判定

常见模板：

1. `preflight`
2. `build`
3. `deploy`
4. `migrate`
5. `verify`
6. `publish`

不要把 `build / deploy / verify / publish` 混成一个黑盒步骤。

### 2. 原始日志默认下沉

默认把详细输出写入日志文件，而不是直接铺在对话里。

建议格式：

- `logs/<workflow>/<timestamp>-preflight.log`
- `logs/<workflow>/<timestamp>-build.log`
- `logs/<workflow>/<timestamp>-deploy.log`
- `logs/<workflow>/<timestamp>-verify.log`

只有阶段失败时，才回显最小必要的尾部片段。

### 3. 每阶段只输出一行摘要

标准格式：

```text
[PASS] build: artifact=/path/app sha256=...
[FAIL] deploy: service failed to restart log=logs/deploy.log
```

摘要必须只包含：

- `PASS` 或 `FAIL`
- 阶段名
- 最关键结果
- 必要路径、哈希、服务状态或接口证据

不要贴整段命令输出。

### 4. 成功必须强判定

不要用这些弱信号判断成功：

- “看起来没报错”
- “日志差不多结束了”
- “应该已经部署上了”
- “大概率是好的”

优先用这些强证据：

- 文件存在
- 哈希一致
- 命令退出码正确
- 服务状态为 `active`
- 接口返回符合预期
- 新资源名已切换
- 目标进程或端口确实存在

如果没有强证据，就不要报成功。

### 5. 失败先修最小原因

阶段失败时：

1. 定位失败阶段
2. 提取最小关键错误
3. 修最局部、最确定的问题
4. 从当前阶段或必要前置阶段重跑

不要无意义整链重试，也不要在多个原因上同时下注。

### 6. 文档和脚本一起沉淀

如果某条流程反复出现，优先沉淀成：

- 脚本
- skill
- SOP
- Markdown 现场记录

已确认的环境事实、业务约束、排障结论，不要只留在聊天里。

## Good Defaults

- 优先脚本化固定流程，而不是长期依赖临时 one-liner
- 优先短输出 + 日志文件
- 优先阶段复跑，而不是全量重跑
- 优先机器可验证结果，而不是主观判断
- 优先把发布和提交拆开，除非用户要求一起做

## Reusable Scaffold

如果项目里还没有现成流水线脚本，优先从本 skill 自带模板起步：

- `scripts/pipeline-template.sh`
- `scripts/remote-deploy-template.sh`

使用方式：

1. 复制模板到项目内，例如 `scripts/pipeline.sh`
2. 替换顶部变量
3. 实现各阶段函数
4. 把强判定条件写进每个阶段
5. 保持摘要输出稳定，不要把详细日志直接打印到终端

模板默认提供：

- 日志目录初始化
- `PASS/FAIL` 摘要输出
- 阶段日志文件
- `run_stage` 包装器
- `preflight/build/deploy/verify` 骨架

其中：

- `pipeline-template.sh` 适合本机或单机流程
- `remote-deploy-template.sh` 适合需要 `ssh` / `scp` / `rsync` / 远端 `systemctl` 的交付流程

不要把模板原样长期放着不改。每个项目都必须把：

- 产物路径
- 目标主机
- 服务名
- 验证命令
- 失败判定

替换成项目自己的实际值。

## Remote Deploy Scaffold

远端部署场景优先从这个模板起步：

- `scripts/remote-deploy-template.sh`

适用场景：

- 构建机和测试机分离
- 需要上传产物到远端
- 需要远端停服务、替换、重启、验活
- 需要比较本地产物和远端运行文件的一致性

模板默认提供：

- 远端主机变量
- 远端 `sha256` 校验
- 远端 `systemctl is-active` 校验
- `scp` / `ssh` 的阶段化包装
- 失败时输出阶段日志路径和最小尾部片段

## Common Failures

### 1. 直接贴海量日志

问题：用户和代理都被噪音拖住，真正关键信息被淹没。

修正：日志下沉，摘要上浮。

### 2. 没有阶段边界

问题：失败时不知道卡在哪，也不知道该从哪里恢复。

修正：先明确阶段，再执行。

### 3. 把“没看到报错”当成功

问题：最容易造成假阳性。

修正：每个阶段提前定义强判定条件。

### 4. 同时改三件事再重跑

问题：失败原因被混淆，反馈回路失真。

修正：一次只修一个最可能的局部原因。

## Minimal Template

在开始执行前，先形成这样的内部结构：

```text
Stage 1: preflight
- prove hosts/tools/paths are ready

Stage 2: build
- produce artifact
- verify artifact exists and hashable

Stage 3: deploy
- move artifact to target
- verify runtime artifact matches build artifact

Stage 4: verify
- prove service/api/runtime behavior
```

如果这套结构还没形成，就不要直接进入长流程执行。
