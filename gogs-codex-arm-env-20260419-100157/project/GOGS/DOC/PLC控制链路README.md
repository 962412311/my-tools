# PLC 控制链路 README

## 目标

这份文档说明当前 PLC 控制链路的模块边界、寄存器主线、远控会话机制，以及前后端的职责分工。

重点是避免后续继续把：

- 寄存器语义
- 远控会话
- 控制 API
- 前端操作行为

混成一层。

## 链路概览

当前 PLC 控制链路分成三层：

1. Modbus 协议与寄存器层
2. HTTP 远控会话与控制 API 层
3. 前端控制页面层

```text
Frontend
   |
   +-> /api/control/*
   |
HttpServer
   |
   +-> session / ownership / API validation
   |
ModbusClient
   |
   +-> HR / IR registers
   +-> command ack / result / heartbeat
   |
PLC
```

## 协议与寄存器层

核心类：

- `backend/include/protocols/modbus/ModbusClient.h`
- `backend/src/protocols/modbus/ModbusClient.cpp`

### 输入寄存器主线

输入寄存器主要承载 PLC -> 上位机状态：

- 位置：`IR_POS_X / Y / Z`
- 姿态：`IR_ANGLE_THETA`
- 抓斗与载重：`IR_GRAB_ANGLE / IR_LOAD_WEIGHT`
- 状态字：`IR_STATUS_WORD`
- 故障码：`IR_FAULT_CODE`
- 模式：`IR_OP_MODE`
- 作业阶段：`IR_JOB_STAGE`
- 心跳：`IR_HEARTBEAT_PLC`
- 速度：`IR_VEL_X / Y / Z / THETA`

`ModbusClient` 会把这些寄存器解析成：

- `PlcData`
- `GantryPose`

### 保持寄存器主线

保持寄存器主要承载上位机 -> PLC 控制：

- 命令区：`HR_CONTROL_CMD / PARAM`
- 模式请求：`HR_MODE_REQUEST`
- 急停：`HR_EMERGENCY_STOP`
- 目标位姿：`HR_TARGET_X / Y / Z / THETA`
- 最高点写入：`HR_HIGHEST_X / Y / Z / Z_ABS`
- 命令确认链：`HR_CMD_TIMESTAMP / SEQ / STATUS / RESULT / WRITE_CONFIRM`
- 诊断区：`HR_DIAG_*`
- 安全与速度限制：`HR_MAX_VEL_* / HR_MAX_ACC_* / HR_SAFE_LIMIT_*`

当前已经按 PLC V2.0 主线把这些寄存器接到真实写链路。

## 命令模型

命令常量定义在：

- `PlcCommands`

主要包括：

- `CMD_MOVE_X / Y / Z`
- `CMD_ROTATE`
- `CMD_GOTO`
- `CMD_AUTO_START`
- `CMD_AUTO_STOP`
- `CMD_RESET`
- `CMD_CLEAR_FAULT`

模式常量：

- `MODE_AUTO`
- `MODE_MANUAL`
- `MODE_REMOTE`

作业阶段常量：

- `STAGE_IDLE`
- `STAGE_SCANNING`
- `STAGE_ANALYZING`
- `STAGE_POSITIONING`
- `STAGE_GRABBING`
- `STAGE_MOVING`
- `STAGE_PLACING`
- `STAGE_COMPLETED`
- `STAGE_ERROR`

## `ModbusClient` 的职责

`ModbusClient` 当前负责：

1. 建立 TCP 或 RTU 连接
2. 轮询输入寄存器和状态寄存器
3. 写心跳、最高点、目标位姿和控制命令
4. 处理写确认、命令状态、命令结果
5. 输出位姿、故障、模式变化和命令完成事件

### 已有保护

- `PlcData::isValid()` 已收紧到同时校验 `X/Y/Z`
- 最高点写入只在 `HighestPoint.valid == true` 时触发
- 控制命令不再以“写成功”直接当成“执行完成”
- 已补 `HR_WRITE_CONFIRM / HR_CMD_STATUS / HR_CMD_RESULT` 主线

### 不应该放到这里的内容

- HTTP 会话所有权
- 页面交互状态
- 前端按钮逻辑

这些都不应该继续塞进 `ModbusClient`

## 远控会话与 HTTP 控制层

核心文件：

- `backend/include/service/HttpServer.h`
- `backend/src/service/HttpServer.cpp`

### 会话模型

`HttpServer` 当前持有：

- `m_controlSessions`
- `m_controllingSession`

会话结构：

- `sessionId`
- `operatorName`
- `startTime`
- `lastActivity`
- `hasControl`

### 当前控制接口

- `POST /api/control/request`
- `POST /api/control/release`
- `GET /api/control/status`
- `GET /api/control/statistics`
- `POST /api/control/move`
- `POST /api/control/goto`
- `POST /api/control/stop`
- `POST /api/control/emergency`
- `POST /api/control/mode`
- `POST /api/control/reset`
- `POST /api/control/clear-fault`

### `HttpServer` 的职责

- 分配远控会话
- 保证同一时刻只有一个控制会话
- 校验 session 是否有效
- 把业务 API 映射到 `ModbusClient`

### 当前策略

- 普通控制命令必须持有当前控制权
- 急停允许走 `allowEmergency` 分支
- 释放控制时会尝试切回手动模式

## 前端控制层

当前主要消费控制链路的页面：

- `frontend/src/views/RemoteOperationView.vue`
- `frontend/src/views/MonitorView.vue`

统一 API 封装在：

- `frontend/src/services/api.js`

前端负责：

- 申请控制权
- 维护 `sessionId`
- 发起 `move / goto / stop / emergency / mode / reset / clear-fault`
- 展示 PLC 状态和统计

前端不负责：

- 解释寄存器细节
- 自己维护命令确认状态机
- 绕过会话直接控制 PLC

## 命令完成语义

当前项目已经做过一次关键收口：

- 不再把“写寄存器成功”视为命令完成
- 命令完成要看 PLC 返回的确认/状态/结果寄存器

也就是说，控制链路的真实语义是：

1. 上位机写入命令
2. PLC 回确认
3. PLC 更新命令状态
4. PLC 给出命令结果

这样才能避免：

- “命令刚写进去就当成功”
- 前端误判设备已执行完成

## 优先级与互斥

当前已经形成的隐含优先级：

1. 急停
2. 当前持有控制权的会话
3. 普通控制命令

但还没有完全落地的更高层调度问题包括：

- 当前是否处于正式作业阶段
- 自动任务是否占用设备
- 未来“低置信度区域主动补扫”是否允许抢占控制链路

这也是 `todo.md` 里后续要单独设计的内容。

## 当前限制

1. 会话模型当前在 `HttpServer` 内部，尚未拆成独立控制会话管理器
2. 自动任务与远控会话的优先级关系还没有彻底模块化
3. 某些 PLC 协议缺口仍需要按现场速查表继续核实
4. 真实现场仍需要继续验证模式切换、故障清除和急停行为

## 后续开发建议

1. 若继续扩展控制链路，优先抽出独立 `ControlSessionManager`
2. 若继续扩展自动任务，避免让 `HttpServer` 直接承担调度决策
3. 若接入“主动补扫”，建议只消费控制 API，不要直接跨层操作 `ModbusClient`
4. 寄存器变更继续只在 `ModbusClient` 层处理

## 代码入口

- `backend/include/protocols/modbus/ModbusClient.h`
- `backend/src/protocols/modbus/ModbusClient.cpp`
- `backend/src/service/HttpServer.cpp`
- `frontend/src/services/api.js`
- `frontend/src/views/RemoteOperationView.vue`
- `frontend/src/views/MonitorView.vue`
