# GOGS PLC接口通讯协议 V2.0

> 版本: 2.0  
> 更新日期: 2026-03-16  
> 适用范围: 抓斗作业引导及盘存系统 (GOGS)  
> 通讯方式: Modbus TCP/RTU

---

## 1. 协议概述

### 1.1 设计目标

本协议V2.0版本旨在解决V1.0存在的以下问题：
- ❌ 寄存器数量不足，无法扩展
- ❌ 缺少写入确认机制
- ❌ 心跳机制单向
- ❌ 远程操作控制能力不足
- ❌ 缺少安全保护机制
- ❌ 错误码传递不完善

### 1.2 核心改进

| 改进项 | V1.0 | V2.0 |
|--------|------|------|
| 输入寄存器 | 9个 | 32个 |
| 保持寄存器 | 14个 | 64个 |
| 心跳机制 | 单向 | 双向 |
| 写入确认 | 无 | 有 |
| 控制指令 | 无 | 完整支持 |
| 安全机制 | 无 | 多层保护 |
| 错误码 | 无 | 详细定义 |

### 1.3 通讯架构

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           GOGS 系统通讯架构 V2.0                             │
└─────────────────────────────────────────────────────────────────────────────┘

                                    前端层
                              ┌─────────────────┐
                              │  Vue.js 前端    │
                              │  ├─ 自动模式    │
                              │  ├─ 手动模式    │
                              │  └─ 远程操作    │
                              └────────┬────────┘
                                       │ HTTP/WebSocket
                                       ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              后端服务层 (Qt/C++)                             │
│  ┌─────────────────────────────────────────────────────────────────────────┐│
│  │                          ModbusClient                                   ││
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     ││
│  │  │  DataReader │  │ DataWriter  │  │CommandHandler│  │SafetyMonitor│     ││
│  │  │   (20Hz)    │  │   (10Hz)    │  │  (事件驱动)  │  │  (实时监控)  │     ││
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘     ││
│  │         └─────────────────┴─────────────────┴─────────────────┘          ││
│  │                                    │                                      ││
│  │                                    ▼                                      ││
│  │                         ┌─────────────────────┐                          ││
│  │                         │    ModbusClient     │                          ││
│  │                         │  (TCP/RTU双模式)     │                          ││
│  │                         └──────────┬──────────┘                          ││
│  └────────────────────────────────────┼─────────────────────────────────────┘│
└───────────────────────────────────────┼──────────────────────────────────────┘
                                        │ Modbus TCP (Port 502)
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                              PLC 控制器                                      │
│  ┌─────────────────────────────┐  ┌─────────────────────────────────────────┐│
│  │     输入寄存器 (IR)          │  │           保持寄存器 (HR)                ││
│  │  0x0000-0x001F (32个)       │  │      0x0064-0x00A3 (64个)               ││
│  │  ├─ 位姿数据区 (0-11)       │  │  ├─ 控制指令区 (100-115)                ││
│  │  ├─ 状态数据区 (12-19)      │  │  ├─ 目标点数据区 (116-131)              ││
│  │  ├─ 运动数据区 (20-27)      │  │  ├─ 参数配置区 (132-147)                ││
│  │  └─ 预留扩展区 (28-31)      │  │  └─ 诊断数据区 (148-163)                ││
│  └─────────────────────────────┘  └─────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## 2. 寄存器映射 V2.0

### 2.1 输入寄存器 (Input Registers) - 只读

**地址范围: 0x0000 - 0x001F (0-31)**

#### 2.1.1 位姿数据区 (0x0000-0x000B)

| 地址 | 名称 | 类型 | 说明 | 单位 |
|------|------|------|------|------|
| 0x0000-0x0001 | IR_POS_X | float32 | 大车位置 (X坐标) | 米(m) |
| 0x0002-0x0003 | IR_POS_Y | float32 | 小车位置 (Y坐标) | 米(m) |
| 0x0004-0x0005 | IR_POS_Z | float32 | 起升高度 (Z坐标) | 米(m) |
| 0x0006-0x0007 | IR_ANGLE_THETA | float32 | 旋转角度 | 度(°) |
| 0x0008-0x0009 | IR_GRAB_ANGLE | float32 | 抓斗开度 | 度(°) |
| 0x000A-0x000B | IR_LOAD_WEIGHT | float32 | 负载重量 | 吨(t) |

#### 2.1.2 状态数据区 (0x000C-0x0013)

| 地址 | 名称 | 类型 | 说明 |
|------|------|------|------|
| 0x000C | IR_STATUS_WORD | uint16 | 状态字 (详见2.3.1) |
| 0x000D | IR_FAULT_CODE | uint16 | 故障码 (详见2.3.3) |
| 0x000E-0x000F | IR_TIMESTAMP | uint32 | PLC时间戳 (毫秒) |
| 0x0010 | IR_OP_MODE | uint16 | 当前操作模式 (0=自动/1=手动/2=远程) |
| 0x0011 | IR_JOB_STAGE | uint16 | 作业阶段 (详见2.3.4) |
| 0x0012-0x0013 | IR_HEARTBEAT_PLC | uint32 | PLC心跳计数器 |

#### 2.1.3 运动数据区 (0x0014-0x001B)

| 地址 | 名称 | 类型 | 说明 | 单位 |
|------|------|------|------|------|
| 0x0014-0x0015 | IR_VEL_X | float32 | X轴速度 | m/s |
| 0x0016-0x0017 | IR_VEL_Y | float32 | Y轴速度 | m/s |
| 0x0018-0x0019 | IR_VEL_Z | float32 | Z轴速度 | m/s |
| 0x001A-0x001B | IR_VEL_THETA | float32 | 旋转角速度 | °/s |

#### 2.1.4 预留扩展区 (0x001C-0x001F)

| 地址 | 名称 | 类型 | 说明 |
|------|------|------|------|
| 0x001C-0x001D | IR_RESERVED_1 | uint32 | 预留 |
| 0x001E-0x001F | IR_RESERVED_2 | uint32 | 预留 |

### 2.2 保持寄存器 (Holding Registers) - 读写

**地址范围: 0x0064 - 0x00A3 (100-163)**

#### 2.2.1 控制指令区 (0x0064-0x0073)

| 地址 | 名称 | 类型 | 说明 | 权限 |
|------|------|------|------|------|
| 0x0064 | HR_CONTROL_CMD | uint16 | 控制指令字 (详见2.3.5) | W |
| 0x0065 | HR_CONTROL_PARAM | uint16 | 控制参数 | W |
| 0x0066 | HR_EMERGENCY_STOP | uint16 | 急停指令 (0xA55A=急停) | W |
| 0x0067 | HR_MODE_REQUEST | uint16 | 模式请求 (0=自动/1=手动/2=远程) | W |
| 0x0068-0x0069 | HR_HEARTBEAT_HOST | uint32 | 主机心跳计数器 | W |
| 0x006A-0x006B | HR_CMD_TIMESTAMP | uint32 | 指令时间戳 | W |
| 0x006C | HR_CMD_SEQ | uint16 | 指令序列号 | W |
| 0x006D | HR_CMD_STATUS | uint16 | 指令执行状态 (R/W) | R/W |
| 0x006E-0x006F | HR_CMD_RESULT | uint32 | 指令执行结果 | R |
| 0x0070-0x0071 | HR_RESERVED_CMD | uint32 | 预留指令 | - |
| 0x0072-0x0073 | HR_WRITE_CONFIRM | uint32 | 写入确认码 | R |

#### 2.2.2 目标点数据区 (0x0074-0x0083)

| 地址 | 名称 | 类型 | 说明 | 单位 |
|------|------|------|------|------|
| 0x0074-0x0075 | HR_TARGET_X | float32 | 目标X坐标 | 米(m) |
| 0x0076-0x0077 | HR_TARGET_Y | float32 | 目标Y坐标 | 米(m) |
| 0x0078-0x0079 | HR_TARGET_Z | float32 | 目标Z坐标 | 米(m) |
| 0x007A-0x007B | HR_TARGET_THETA | float32 | 目标角度 | 度(°) |
| 0x007C-0x007D | HR_HIGHEST_X | float32 | 最高点X坐标 | 米(m) |
| 0x007E-0x007F | HR_HIGHEST_Y | float32 | 最高点Y坐标 | 米(m) |
| 0x0080-0x0081 | HR_HIGHEST_Z | float32 | 最高点Z坐标 | 米(m) |
| 0x0082-0x0083 | HR_HIGHEST_Z_ABS | float32 | 最高点绝对Z | 米(m) |

实现约定：
- `HR_HIGHEST_X / HR_HIGHEST_Y / HR_HIGHEST_Z` 当前按**相对坐标最高点**解释，对应抓斗/行车局部坐标系
- `HR_HIGHEST_Z_ABS` 表示世界坐标系下的绝对高度 `Z`
- 这一约定沿用系统原有 `HighestPoint.relative / absolute` 数据结构，避免在 PLC 与点云业务链之间引入额外坐标歧义

#### 2.2.3 参数配置区 (0x0084-0x0093)

| 地址 | 名称 | 类型 | 说明 | 单位 |
|------|------|------|------|------|
| 0x0084-0x0085 | HR_MAX_VEL_X | float32 | X轴最大速度 | m/s |
| 0x0086-0x0087 | HR_MAX_VEL_Y | float32 | Y轴最大速度 | m/s |
| 0x0088-0x0089 | HR_MAX_VEL_Z | float32 | Z轴最大速度 | m/s |
| 0x008A-0x008B | HR_MAX_ACC_X | float32 | X轴最大加速度 | m/s² |
| 0x008C-0x008D | HR_MAX_ACC_Y | float32 | Y轴最大加速度 | m/s² |
| 0x008E-0x008F | HR_MAX_ACC_Z | float32 | Z轴最大加速度 | m/s² |
| 0x0090-0x0091 | HR_SAFE_LIMIT_X | float32 | X轴安全限位 | 米(m) |
| 0x0092-0x0093 | HR_SAFE_LIMIT_Y | float32 | Y轴安全限位 | 米(m) |

#### 2.2.4 诊断数据区 (0x0094-0x00A3)

| 地址 | 名称 | 类型 | 说明 |
|------|------|------|------|
| 0x0094-0x0095 | HR_DIAG_COMM_COUNT | uint32 | 通讯计数 |
| 0x0096-0x0097 | HR_DIAG_COMM_ERROR | uint32 | 通讯错误计数 |
| 0x0098-0x0099 | HR_DIAG_LAST_ERROR | uint32 | 最后错误码 |
| 0x009A-0x009B | HR_DIAG_UPTIME | uint32 | 运行时间(秒) |
| 0x009C-0x009D | HR_DIAG_TEMP | float32 | 设备温度 |
| 0x009E-0x009F | HR_DIAG_VOLTAGE | float32 | 电源电压 |
| 0x00A0-0x00A1 | HR_RESERVED_DIAG1 | uint32 | 预留 |
| 0x00A2-0x00A3 | HR_RESERVED_DIAG2 | uint32 | 预留 |

---

## 3. 数据格式定义

### 3.1 状态字 (IR_STATUS_WORD)

```
Bit 0: 运行状态 (1=运行中, 0=停止)
Bit 1: 故障状态 (1=存在故障, 0=正常)
Bit 2: 急停状态 (1=急停触发, 0=正常)
Bit 3: 自动模式 (1=自动模式, 0=非自动)
Bit 4: 手动模式 (1=手动模式, 0=非手动)
Bit 5: 远程模式 (1=远程模式, 0=非远程)
Bit 6: 作业中标识 (1=作业中, 0=空闲)
Bit 7: 负载状态 (1=超载, 0=正常)
Bit 8-15: 预留
```

实现约定：
- 以上位定义按现场最新 [`PLC接口通讯协议接口速查表V1.1.docx`](PLC接口通讯协议接口速查表V1.1.docx) 收口
- 后端、HTTP 接口和前端状态展示均按这组位定义解释 `IR_STATUS_WORD`

### 3.2 系统状态收口说明

```
本版本不再单独定义 `HR_SYSTEM_STATUS` 保持寄存器。
系统运行、故障、急停和模式状态统一通过 `IR_STATUS_WORD` 表达。
```

实现备注：
- `V1.1` 速查表没有给出独立的 `HR_SYSTEM_STATUS` 地址
- 为避免与 `HR_CMD_STATUS` 等控制状态寄存器冲突，后端不再向不存在的系统状态保持寄存器写值
- 如果后续确实需要独立的系统状态寄存器，必须先在寄存器映射表中补齐明确地址，再扩展实现

### 3.3 故障码 (IR_FAULT_CODE)

| 代码 | 名称 | 说明 | 处理建议 |
|------|------|------|----------|
| 0x0000 | FAULT_NONE | 无故障 | - |
| 0x0001 | FAULT_COMM | 通讯故障 | 检查网络连接 |
| 0x0002 | FAULT_TIMEOUT | 通讯超时 | 检查PLC状态 |
| 0x0003 | FAULT_HEARTBEAT | 心跳丢失 | 重启通讯 |
| 0x0010 | FAULT_X_LIMIT | X轴限位触发 | 检查位置 |
| 0x0011 | FAULT_Y_LIMIT | Y轴限位触发 | 检查位置 |
| 0x0012 | FAULT_Z_LIMIT | Z轴限位触发 | 检查位置 |
| 0x0020 | FAULT_X_SERVO | X轴伺服故障 | 检查驱动器 |
| 0x0021 | FAULT_Y_SERVO | Y轴伺服故障 | 检查驱动器 |
| 0x0022 | FAULT_Z_SERVO | Z轴伺服故障 | 检查驱动器 |
| 0x0030 | FAULT_OVERLOAD | 超载 | 减少负载 |
| 0x0031 | FAULT_GRAB_FAULT | 抓斗故障 | 检查抓斗 |
| 0x0040 | FAULT_EMERGENCY | 急停触发 | 复位急停 |
| 0x00FF | FAULT_UNKNOWN | 未知故障 | 联系维护 |

### 3.4 作业阶段 (IR_JOB_STAGE)

| 值 | 名称 | 说明 |
|----|------|------|
| 0 | STAGE_IDLE | 空闲 |
| 1 | STAGE_SCANNING | 扫描中 |
| 2 | STAGE_ANALYZING | 分析中 |
| 3 | STAGE_POSITIONING | 定位中 |
| 4 | STAGE_GRABBING | 抓取中 |
| 5 | STAGE_MOVING | 移动中 |
| 6 | STAGE_PLACING | 放置中 |
| 7 | STAGE_COMPLETED | 完成 |
| 8 | STAGE_ERROR | 错误 |

### 3.5 控制指令字 (HR_CONTROL_CMD)

| 值 | 名称 | 说明 | 参数 |
|----|------|------|------|
| 0x0000 | CMD_NONE | 无指令 | - |
| 0x0001 | CMD_MOVE_X | X轴移动 | HR_CONTROL_PARAM: 0=停止, 1=正向, 2=负向 |
| 0x0002 | CMD_MOVE_Y | Y轴移动 | HR_CONTROL_PARAM: 0=停止, 1=正向, 2=负向 |
| 0x0003 | CMD_MOVE_Z | Z轴移动 | HR_CONTROL_PARAM: 0=停止, 1=上升, 2=下降 |
| 0x0004 | CMD_ROTATE | 旋转 | HR_CONTROL_PARAM: 0=停止, 1=正转, 2=反转 |
| 0x0005 | CMD_GRAB | 抓斗控制 | HR_CONTROL_PARAM: 0=停止, 1=打开, 2=闭合 |
| 0x0010 | CMD_GOTO | 移动到目标点 | 使用HR_TARGET_X/Y/Z/THETA |
| 0x0020 | CMD_AUTO_START | 自动模式启动 | - |
| 0x0021 | CMD_AUTO_STOP | 自动模式停止 | - |
| 0x0030 | CMD_RESET | 系统复位 | - |
| 0x0031 | CMD_CLEAR_FAULT | 清除故障 | - |
| 0x00A5 | CMD_CONFIRM | 写入确认 | 确认写入数据有效 |

---

## 4. 通讯机制

### 4.1 心跳机制 (双向)

```

当前实现约定：
- 主机每 `100ms` 递增并写入 `HR_HEARTBEAT_HOST`
- 后端以 `IR_HEARTBEAT_PLC` 的**连续变化**作为 PLC 存活判断依据
- 若 `500ms` 内 `IR_HEARTBEAT_PLC` 无变化，则判定心跳超时
- 当前实现不要求 `IR_HEARTBEAT_PLC` 与主机心跳数值严格相等，只要求 PLC 侧心跳持续更新
主机 ──────────────────────────────────────────────────────────────► PLC
     │                                                          │
     │  ┌────────────────────────────────────────────────────┐  │
     │  │ 主机心跳 (HR_HEARTBEAT_HOST)                        │  │
     │  │ - 主机每100ms递增计数器                             │  │
     │  │ - PLC读取并回写到IR_HEARTBEAT_PLC                   │  │
     │  │ - 主机检查回写值，延迟<200ms为正常                   │  │
     │  └────────────────────────────────────────────────────┘  │
     │                                                          │
     │  ◄──────────────────────────────────────────────────────  │
     │                                                          │
     │  ┌────────────────────────────────────────────────────┐  │
     │  │ PLC心跳 (IR_HEARTBEAT_PLC)                          │  │
     │  │ - PLC每50ms递增计数器                               │  │
     │  │ - 主机读取并监控变化                                │  │
     │  │ - 500ms无变化判定为通讯异常                          │  │
     │  └────────────────────────────────────────────────────┘  │
```

### 4.2 写入确认机制

```
主机写入流程:
1. 主机写入数据到保持寄存器
2. 主机写入确认码 (HR_WRITE_CONFIRM = 0xA5A5)
3. PLC检测到确认码，读取数据并执行
4. PLC清零确认码 (HR_WRITE_CONFIRM = 0x0000)
5. 主机读取到确认码为0，确认写入成功

超时处理:
- 500ms内未检测到确认码清零，判定写入失败
- 重试3次后仍失败，上报通讯故障
```

### 4.3 控制指令执行流程

```
┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐     ┌─────────┐
│  空闲   │────►│ 写入指令 │────►│ 确认请求 │────►│ PLC执行 │────►│ 完成确认 │
│         │     │         │     │         │     │         │     │         │
└─────────┘     └────┬────┘     └────┬────┘     └────┬────┘     └────┬────┘
      ▲              │               │               │               │
      │              │               │               │               │
      │              ▼               ▼               ▼               ▼
      │         写入HR_        写入HR_        PLC读取      读取IR_
      │         CONTROL_       CMD_CONFIRM    并执行       CMD_STATUS
      │         CMD + PARAM    = 0xA5A5                      = DONE
      │              │               │               │               │
      │              │               │               │               │
      └──────────────┴───────────────┴───────────────┴───────────────┘
                                    
超时处理 (每个阶段500ms超时):
- 阶段2→3超时: 重试写入确认码
- 阶段3→4超时: 上报PLC无响应
- 阶段4→5超时: 上报执行超时

当前实现约定：
- 后端不会再以“保持寄存器写成功”直接当作“控制指令执行完成”
- 只有在 `HR_WRITE_CONFIRM` 经 PLC 清零且 `HR_CMD_STATUS / HR_CMD_RESULT` 进入可判定的完成状态后，后端才结束该指令的执行跟踪
- 后端写链路按寄存器分块写入：
  - 心跳区
  - 最高点区
  - 模式请求区
  - 目标点区
  - 控制指令区
- 不再每 `100ms` 全量覆写 64 个保持寄存器，避免覆盖 PLC 状态区、诊断区和确认区
```

### 4.4 通讯频率

| 操作 | 频率 | 周期 | 说明 |
|------|------|------|------|
| 读取输入寄存器 | 20Hz | 50ms | 读取位姿、状态、心跳 |
| 写入保持寄存器 | 10Hz | 100ms | 写入目标点、心跳、状态 |
| 控制指令 | 事件驱动 | - | 有指令时立即发送 |
| 急停指令 | 最高优先级 | - | 立即发送，无延迟 |

---

## 5. 安全机制

### 5.1 模式互锁

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           操作模式互锁逻辑                                   │
└─────────────────────────────────────────────────────────────────────────────┘

模式切换请求:
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│  当前模式 │───►│ 检查条件  │───►│ 执行切换  │───►│ 确认切换  │
└──────────┘    └──────────┘    └──────────┘    └──────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│ 切换条件表:                                                                  │
│ ┌─────────────┬─────────────┬─────────────────────────────────────────────┐ │
│ │ 当前模式    │ 目标模式    │ 切换条件                                    │ │
│ ├─────────────┼─────────────┼─────────────────────────────────────────────┤ │
│ │ 自动        │ 手动        │ 当前作业完成或暂停                          │ │
│ │ 自动        │ 远程        │ 当前作业完成或暂停 + 远程授权               │ │
│ │ 手动        │ 自动        │ 所有轴停止 + 无故障                         │ │
│ │ 手动        │ 远程        │ 所有轴停止 + 远程授权                       │ │
│ │ 远程        │ 自动        │ 远程释放控制 + 所有轴停止                   │ │
│ │ 远程        │ 手动        │ 远程释放控制 + 所有轴停止                   │ │
│ └─────────────┴─────────────┴─────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 5.2 软限位保护

```
参数配置 (HR_SAFE_LIMIT_X/Y):
- 定义安全区域边界
- 当位置接近边界时，自动减速
- 当位置超出边界时，自动停止并报警

保护逻辑:
if (pos > SAFE_LIMIT - WARNING_ZONE) {
    velocity = velocity * 0.5;  // 减速50%
}
if (pos > SAFE_LIMIT) {
    velocity = 0;  // 停止
    fault_code = FAULT_X_LIMIT;  // 报限位故障
}
```

### 5.3 通讯超时保护

```
超时检测:
- 心跳超时: 500ms未收到PLC心跳
- 写入超时: 500ms未收到写入确认
- 指令超时: 500ms未收到指令执行确认

超时处理:
1. 第一次超时: 重试
2. 第二次超时: 重试 + 报警
3. 第三次超时: 停止自动模式 + 上报故障
```

### 5.4 急停机制

```
急停指令 (HR_EMERGENCY_STOP):
- 写入 0xA55A 触发急停
- 最高优先级，立即执行
- 所有轴立即停止
- 断开所有控制输出

急停复位:
1. 确认故障已清除
2. 写入 CMD_RESET (0x0030)
3. 系统返回待机状态
```

---

## 6. 远程操作协议

### 6.1 WebSocket消息格式

```json
// 主机 → 前端: 位姿数据推送 (20Hz)
{
  "type": "gantryPose",
  "timestamp": 1710500000000,
  "data": {
    "x": 45.123,
    "y": 12.456,
    "z": 8.789,
    "theta": 30.0,
    "grabAngle": 45.0,
    "loadWeight": 5.5,
    "status": 0x0003,
    "faultCode": 0x0000,
    "opMode": 2,
    "jobStage": 0
  }
}

// 前端 → 主机: 控制指令
{
  "type": "controlCommand",
  "timestamp": 1710500000100,
  "seq": 123,
  "data": {
    "command": "moveX",
    "param": 1,
    "targetX": 50.0,
    "targetY": 15.0,
    "targetZ": 10.0
  }
}

// 主机 → 前端: 指令确认
{
  "type": "commandAck",
  "timestamp": 1710500000101,
  "seq": 123,
  "data": {
    "status": "accepted",
    "estimatedTime": 5000
  }
}

// 主机 → 前端: 执行结果
{
  "type": "commandResult",
  "timestamp": 1710500005101,
  "seq": 123,
  "data": {
    "status": "completed",
    "actualX": 50.002,
    "actualY": 15.001,
    "actualZ": 10.0
  }
}
```

### 6.2 远程操作API

```
POST /api/control/move
请求体:
{
  "axis": "X",        // X/Y/Z/THETA/GRAB
  "direction": 1,     // 0=停止, 1=正向/上升/打开, 2=负向/下降/闭合
  "speed": 50         // 速度百分比 (0-100)
}
响应:
{
  "success": true,
  "commandId": "cmd-123456",
  "message": "指令已接受"
}

POST /api/control/goto
请求体:
{
  "x": 50.0,
  "y": 15.0,
  "z": 10.0,
  "theta": 30.0
}
响应:
{
  "success": true,
  "commandId": "cmd-123457",
  "estimatedTime": 8000
}

POST /api/control/stop
请求体: {}
响应:
{
  "success": true,
  "message": "所有轴已停止"
}

POST /api/control/emergency
请求体: {}
响应:
{
  "success": true,
  "message": "急停已触发"
}

POST /api/control/mode
请求体:
{
  "mode": "remote"    // auto/manual/remote
}
响应:
{
  "success": true,
  "currentMode": "remote"
}
```

---

## 7. 实现参考

### 7.1 寄存器读写示例

```cpp
// 读取位姿数据
GantryPose pose;
pose.x = readInputRegisterFloat32(IR_POS_X);
pose.y = readInputRegisterFloat32(IR_POS_Y);
pose.z = readInputRegisterFloat32(IR_POS_Z);
pose.theta = readInputRegisterFloat32(IR_ANGLE_THETA);

// 写入目标点
writeHoldingRegisterFloat32(HR_TARGET_X, target.x);
writeHoldingRegisterFloat32(HR_TARGET_Y, target.y);
writeHoldingRegisterFloat32(HR_TARGET_Z, target.z);
writeHoldingRegister(HR_CONTROL_CMD, CMD_GOTO);
writeHoldingRegister(HR_WRITE_CONFIRM, 0xA5A5);
```

### 7.2 心跳检测示例

```cpp
// 主机心跳发送
void sendHeartbeat() {
    static uint32_t heartbeat = 0;
    writeHoldingRegister32(HR_HEARTBEAT_HOST, ++heartbeat);
}

// PLC心跳检测
void checkPlcHeartbeat() {
    static uint32_t lastHeartbeat = 0;
    static qint64 lastCheckTime = 0;
    
    uint32_t currentHeartbeat = readInputRegister32(IR_HEARTBEAT_PLC);
    qint64 currentTime = QDateTime::currentMSecsSinceEpoch();
    
    if (currentHeartbeat != lastHeartbeat) {
        lastHeartbeat = currentHeartbeat;
        lastCheckTime = currentTime;
    } else if (currentTime - lastCheckTime > 500) {
        // 心跳超时
        handleCommTimeout();
    }
}
```

---

## 8. 版本历史

| 版本 | 日期 | 说明 |
|------|------|------|
| V1.0 | 2024-XX-XX | 初始版本，基础寄存器映射 |
| V2.0 | 2026-03-16 | 全面重构，增加控制指令、安全机制、诊断数据 |

---

## 附录A: 寄存器地址速查表

### 输入寄存器 (0x0000-0x001F)
```
0x0000-0x0001: IR_POS_X
0x0002-0x0003: IR_POS_Y
0x0004-0x0005: IR_POS_Z
0x0006-0x0007: IR_ANGLE_THETA
0x0008-0x0009: IR_GRAB_ANGLE
0x000A-0x000B: IR_LOAD_WEIGHT
0x000C: IR_STATUS_WORD
0x000D: IR_FAULT_CODE
0x000E-0x000F: IR_TIMESTAMP
0x0010: IR_OP_MODE
0x0011: IR_JOB_STAGE
0x0012-0x0013: IR_HEARTBEAT_PLC
0x0014-0x0015: IR_VEL_X
0x0016-0x0017: IR_VEL_Y
0x0018-0x0019: IR_VEL_Z
0x001A-0x001B: IR_VEL_THETA
0x001C-0x001F: IR_RESERVED
```

### 保持寄存器 (0x0064-0x00A3)
```
0x0064: HR_CONTROL_CMD
0x0065: HR_CONTROL_PARAM
0x0066: HR_EMERGENCY_STOP
0x0067: HR_MODE_REQUEST
0x0068-0x0069: HR_HEARTBEAT_HOST
0x006A-0x006B: HR_CMD_TIMESTAMP
0x006C: HR_CMD_SEQ
0x006D: HR_CMD_STATUS
0x006E-0x006F: HR_CMD_RESULT
0x0070-0x0073: HR_RESERVED_CMD
0x0074-0x0075: HR_TARGET_X
0x0076-0x0077: HR_TARGET_Y
0x0078-0x0079: HR_TARGET_Z
0x007A-0x007B: HR_TARGET_THETA
0x007C-0x007D: HR_HIGHEST_X
0x007E-0x007F: HR_HIGHEST_Y
0x0080-0x0081: HR_HIGHEST_Z
0x0082-0x0083: HR_HIGHEST_Z_ABS
0x0084-0x0093: HR_MAX_VEL/ACC/SAFE_LIMIT
0x0094-0x00A3: HR_DIAG_*
```
