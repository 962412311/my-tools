# Runtime Config Issue Ledger

本文件记录“前端接管运行参数”相关的已发现问题，并持续更新修复状态。

补充说明：

- 这份台账当前主要保留问题收口证据，现行主线请优先看 `docs/gogs-rtk.md`、`docs/system-architecture.md` 和新配置中心页面
- 运行参数相关的新增问题，不再回写到旧 `ConfigView` 语义下，统一按新配置中心与 `todo.md` 主线收口

## Current Open

当前无未关闭项。

说明：运行参数链路的现行剩余工作已不属于“前端接管运行参数”专项问题，而是测试机实机验收、点云/视频联调和整体成熟化主线的一部分，统一回写到 `todo.md` 与现行主文档。

## Fixed

说明：下面保留的是“前端接管运行参数”阶段的修复证据，其中涉及旧 `ConfigView` 的条目属于历史问题归档，不再代表当前配置中心入口。

4. `frontend/npm run lint` 最初依赖缺失的 `frontend/.gitignore`，补齐后又暴露出 ESLint 配置缺失，当前无法正确解析 Vue SFC 和 ESM。
状态：已修复
处理策略：补齐前端忽略文件、Vue 3 ESLint 配置和所需解析器依赖；并已清理当前真实 lint 错误，使 `npm run lint` 可作为稳定验证手段。

5. `vite build` 的 Sass 处理链仍输出 `legacy-js-api` 弃用警告。
状态：已修复
结果：前端构建链已升级到 Vite 5，并显式切换到 Sass modern compiler，当前构建不再输出该警告。

1. 运行参数缺少统一白名单/schema，前端可误读写任意 `config_key`。
状态：已修复
结果：后端 `/api/config`、`/api/config/schema` 已收口到运行参数白名单和现有 `ui/*` 兼容键。

2. 旧 `ConfigView` 在前端接管运行参数初期存在模板引用已添加但脚本未接入的脱节问题。
状态：已修复
结果：已补齐 `systemInfo`、快捷跳转、统计项和 `UserManagementView` 导入，并新增静态检查脚本。

3. 大部分 `processing/*`、`camera/*`、`recording/*` 仅持久化，不会在保存后进入运行态。
状态：已修复
结果：`HttpServer::applyRuntimeConfigUpdates()` 已在保存后把相关更新热应用到 `PointCloudProcessor`、`VideoManager` 和相关运行态对象，不再只是单纯持久化。

4. `lidar_calibration/yaw_deg` 未进入点云外参变换链；`R/z` 的消费关系也未明确。
状态：已修复
结果：确认 `R/z` 已在 `LidarDriver` 点云转换链消费，`yaw_deg` 已补入点云处理器外参变换和热应用链。

5. `system/log_level`、`system/ntp_server`、`system/timezone` 仅完成前端配置、接口暴露与持久化，缺少运行时收口。
状态：已修复
结果：`log_level` 和 `timezone` 已接入应用运行时，`ntp_server` 已进入应用运行时状态并通过 `/api/system/info` 暴露当前值。

6. `processing/map_region_size` 从固定值切回 `0` 时，无法恢复自动区域大小。
状态：已修复
结果：已为 `GlobalMapManager` 增加 reset 接口，并在运行参数热应用时对 `0` 正确切回自动区域。

7. WSL/Linux 环境无法直接复用 Windows 安装的 `frontend/node_modules`，导致本地 `npm run build` 失败。
状态：已修复
结果：新增统一前端入口脚本，WSL 挂载盘场景下改走 Linux 隔离工作区，`install/lint/build` 已验证通过。

8. 隔离工作区在并发执行 `lint/build` 时会互相覆盖临时文件，导致 ESLint 偶发读取不到 `vite.config.*.mjs`。
状态：已修复
结果：`frontend-tool` 已增加工作区锁，`lint/build` 并发验证通过。

9. 前端依赖变更后，隔离工作区可能错误复用旧 `node_modules`，导致新增构建插件不会自动安装。
状态：已修复
结果：`frontend-tool` 已把 `package-lock.json` 哈希写入平台标记，锁文件变更会自动重建依赖。

10. `vite build` 当前仍存在大 chunk 警告，主包体积偏大。
状态：已修复
结果：已切换 `echarts` 和 `Element Plus` 为更细粒度拆包与按需引入，并校准构建阈值，当前构建已消除大 chunk 警告。

11. 前端依赖只改 `package.json` 不改 `package-lock.json` 时，隔离工作区不会自动重装依赖。
状态：已修复
结果：`frontend-tool` 已同时校验 `package.json` 与 `package-lock.json` 哈希，任一依赖描述变化都会自动重建 `node_modules`。

12. “算法配置（高级）”与“运行参数”同时编辑同一批 `processing/*` 键，前端存在双入口重复配置。
状态：已修复
结果：`运行参数` 已收口为唯一真实编辑入口；`算法配置（高级）` 改为预设应用、运行参数摘要、测试和业务扩展参数工作台。

13. `frontend-tool` 工作区锁仅按超时清理，异常退出后会残留死锁，后续命令可能长时间等待。
状态：已修复
结果：已增加持锁进程存活检查，检测到失效 PID 会立即清理锁目录并恢复执行。
