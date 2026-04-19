# ARM Cross Compile And Test Skill Archive

这套归档用于当前项目的 ARM 交叉编译、部署和测试流程。

## 内容

- [`SKILL.md`](SKILL.md)：skill 正文
- [`runtime-targets.local.yml`](runtime-targets.local.yml)：当前可直接使用的本地配置
- [`runtime-targets.template.yml`](runtime-targets.template.yml)：本地配置模板

## 说明

- 前端在本机编译，`dist` 同步到测试机
- 后端用 `onebuild_GOGS_backend_self.sh`
- 构建和部署都依赖本地配置中的关键词索引
- 需要路径或命令时，先看 `lookup_index`
- 需要额外仓库、release 包、SDK 或离线资产时，优先在本机下载并整理，再同步到编译机或测试机
- 缺少 apt 包或可直接命令行安装的工具时，可以在目标机器自动安装，但要把安装步骤维护进可复现的环境搭建流程
- 工作过程中确认的环境事实、业务约束、部署结论、排障结果必须及时维护到仓库内对应的 Markdown 文档；代码变更后同轮更新相关文档

## 固定方法论

- 通用方法先遵循全局 `stage-based-execution` skill，再由当前 ARM skill 补充项目专属主机、路径、服务和验活证据
- ARM 相关重复任务优先收敛成固定阶段，而不是在对话里临时拼接长串 `ssh` / `rsync` / `systemctl` 命令
- 推荐阶段：
  - `preflight`
  - `build_backend`
  - `deploy_backend`
  - `deploy_frontend`
  - `verify`
- 每个阶段默认只输出一行摘要：
  - `PASS/FAIL + 关键结果`
- 原始日志默认落文件，不直接刷屏
- 成功判定依赖强证据：
  - 产物存在
  - `sha256` 一致
  - 服务 `active`
  - 线上资源已切换
  - HLS / PTZ / 雷达证据存在
- `build/deploy/verify` 与 `commit/push` 分离；除非用户明确要求，不自动提交和推送

## 推荐入口

如果仓库内已经提供固定流水线脚本，优先使用仓库脚本，而不是重新手写部署命令。例如：

```bash
bash scripts/arm/pipeline.sh
```

常见模式：

```bash
bash scripts/arm/pipeline.sh
bash scripts/arm/pipeline.sh --backend-only
bash scripts/arm/pipeline.sh --frontend-only
bash scripts/arm/pipeline.sh --skip-build-frontend
```
