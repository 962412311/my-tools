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
