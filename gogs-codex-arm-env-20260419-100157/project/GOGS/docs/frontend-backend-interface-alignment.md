# Frontend-Backend Interface Alignment

更新日期：2026-04-16

## 1. 目标

这份文档用于固定当前前后端接口对齐状态，作为配置中心重构收尾、测试机部署验收和后续回归的统一基线。

本轮覆盖范围：

- 当前路由可达的前端页面与 store
- `frontend/src/services/api.js` 暴露的活跃接口
- `backend/src/service/HttpServer.cpp`
- `backend/src/api/HistoryApiHandler.cpp`
- `backend/src/service/WebSocketServer.cpp`

## 2. 本轮已修复

### 2.1 配置中心接口

- 已新增 `GET /api/config-center/summary`
- 已新增 `GET /api/config-center/change-log`
- 已为 `/api/config`、`/api/config/schema`、`/api/config-center/*` 补齐管理员访问保护
- 已为 `POST /api/config` 补齐配置变更审计日志

### 2.2 历史记录接口

- `DashboardView` 与 `HistoryView` 不再直接调用原始 `api.get('/history/today')`
- `HistoryView` 不再直接调用原始 `api.get('/history/export')`
- `api.js` 已统一暴露：
  - `getHistoryToday()`
  - `getHistoryExport(params = {})`
- 后端 `history/export` 已补齐筛选参数透传：
  - `operationType`
  - `operationSource`
  - `pileId`
  - `startTime`
  - `endTime`

### 2.3 远控接口

- `RemoteOperationView` 已删除未知控制指令的裸回退
- 未知命令现在显式报错 `不支持的控制指令`
- 页面层不再直接拼装 `/control/${endpoint}`

## 3. 活跃接口审计结论

### 3.1 审计口径

- 当前活跃接口以“被路由页、当前 store 或新配置中心页面真实引用”为准
- 已退路由的旧 `ConfigView` / `DataManager` 链路不计入主线完成口径
- 页面层原始 `api.get/post/put/delete` 直连调用已清零

### 3.2 已对齐的主线接口域

- 认证与用户
  - `/api/auth/login`
  - `/api/auth/logout`
  - `/api/auth/refresh`
  - `/api/users*`
- 功能开关
  - `/api/features`
  - `/api/features/:type`
- 历史与库存
  - `/api/history/operations`
  - `/api/history/today`
  - `/api/history/export`
  - `/api/history/statistics`
  - `/api/inventory-snapshots*`
  - `/api/inventory/measure`
- 料堆与物料
  - `/api/piles*`
  - `/api/material-types*`
- 视频与 PTZ
  - `/api/video/ptz/*`
  - `/api/video/stream-info`
  - `/api/video/self-check`
  - `/api/video/recording/*`
  - `/api/video-files/*`
- 配置中心
  - `/api/config`
  - `/api/config/schema`
  - `/api/config-center/summary`
  - `/api/config-center/change-log`
  - `/api/scales/status`
  - `/api/scales/devices`
  - `/api/system/maintenance/*`
- 远程控制与补扫
  - `/api/control/*`
  - `/api/rescan/status`
  - `/api/rescan/analyze`
  - `/api/rescan/execute`
  - `/api/rescan/cancel`
- WebSocket
  - `ws/monitor` 当前已稳定发送：
    - `gantryPose`
    - `highestPoint`
    - `processingDiagnostics`
    - `globalMap`

## 4. 遗留接口说明

以下接口仍存在于 `api.js` 或 `data.service.js`，但当前不属于新配置中心和现行主线路由的完成口径：

- `getMaterialOperations`
- `saveMaterialOperation`
- `getBoundaries`
- `saveBoundary`
- `getLogs`
- `saveLog`
- `getStatistics`
- `clearTable`

这些能力主要来自旧 `ConfigView -> DataManager` 链路。当前旧 `ConfigView` 已退路由，因此它们应视为遗留接口，而不是本轮配置中心重构的阻塞项。

## 5. 仍待补齐的真实功能缺口

以下不是“接口对齐误报”，而是当前仓库里仍然明确存在的功能缺口：

- 智能标注层动态位置仍未落地
  - 预期：WebSocket 推送目标跟踪像素坐标或世界坐标
  - 当前：未看到对应后端消息字段

补充说明：

- `PlaybackView` 历史轨迹链路已接入 `/api/monitor/trajectory`
- 该接口当前返回的是历史作业轨迹，不是实时点云短轨迹窗口；后续若要避免误解，应该继续收口接口命名或前端文案
- 旧 `ConfigView.vue` 已裁剪为只读迁移壳，`DataManager` 相关能力仍属遗留链路，但两者都不再作为当前配置中心完成度口径

## 6. 验证证据

本轮已执行并通过：

```bash
rtk bash -lc 'cd frontend && node --test \
  tests/config-center-api-contract.test.mjs \
  tests/config-center-route-contract.test.mjs \
  tests/config-center-domain-contract.test.mjs \
  tests/config-center-page-contract.test.mjs \
  tests/interface-alignment-contract.test.mjs'

rtk npm --prefix frontend run build
```

当前结果：

- 配置中心契约测试：通过
- 接口对齐契约测试：通过
- 前端生产构建：通过

测试机部署与验活结果：

- `rtk bash scripts/arm/preflight.sh`：通过
- 当前工作区源码已 `rsync` 到编译机并完成 ARM 后端构建
- 测试机后端部署：通过
  - runtime sha256: `ffd62b37562844856a42e7c68dd6fb32d07dda442fe44e7ebd642fd96fdc3760`
- 测试机前端部署：通过
  - index asset: `assets/index-vMStQWK8.js`
- `rtk bash scripts/arm/verify_remote.sh`：通过
  - service: `active`
  - HLS header: `#EXTM3U`
- 测试机专项 API 验证：通过
  - `/api/config-center/summary`
  - `/api/config-center/change-log`
  - `/api/config/schema`
  - `/api/history/today`
  - `/api/history/export?operationType=...&operationSource=...&pileId=...`

## 7. 下一步

最后一阶段必须执行：

1. 按测试机部署脚本完整部署前后端到测试机
2. 以这份文档和 `frontend/docs/todo.md` 为验收基线逐项回归
3. 遇到问题继续回写代码、文档和清单，直到测试机问题清零
