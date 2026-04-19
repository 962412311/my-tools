# 称重设备现场协议核对 SOP

## 目标

把称重设备接入从“接口能通”提升到“协议语义、采样节奏和换算口径都可核对、可留痕”。

本 SOP 固定用于当前项目的真实称重设备联调，不替代设备厂商手册。

固定入口：

- `rtk bash scripts/arm/verify_scale_protocol.sh`
- [`称重设备协议验收记录模板`](称重设备协议验收记录模板.md)
- `ui/scale_devices`
- `GET /api/scales/status`

## 核对前提

- 目标机后端已运行，且登录账号具备配置中心权限。
- 称重设备已经按现场接线方案接入，串口或网口参数可确认。
- 设备侧当前寄存器表、字节序、单位和异常码说明已经拿到。
- 本轮只在测试机做验收，不在测试机本地编译；涉及后端改动仍只走编译机。

## 第一步：确认现场协议基线

至少先确认这些事实，再进入脚本核对：

- 设备编号、厂家、型号、协议版本
- 通讯方式：`Modbus TCP` 或 `Modbus RTU`
- `slaveId`
- `registerArea / registerAddress / registerCount`
- `valueType / wordOrder / scaleFactor`
- 目标采样周期或心跳周期
- 原始单位、业务单位和换算关系
- 设备异常码或状态字语义

建议把期望映射先整理成 JSON，后面直接喂给脚本：

```json
{
  "devices": [
    {
      "id": 1,
      "name": "Scale-A",
      "type": "tcp",
      "protocol": "modbus",
      "slaveId": 1,
      "registerArea": "holding",
      "registerAddress": 0,
      "registerCount": 2,
      "valueType": "float32",
      "wordOrder": "ab",
      "scaleFactor": 0.01,
      "pollIntervalMs": 1000
    }
  ]
}
```

## 第二步：跑固定脚本

无期望映射时，先做结构化体检：

```bash
rtk bash scripts/arm/verify_scale_protocol.sh
```

有现场期望映射时，直接做字段级对照：

```bash
SCALE_VERIFY_EXPECTED_SPEC='{"devices":[{"id":1,"name":"Scale-A","type":"tcp","protocol":"modbus","slaveId":1,"registerArea":"holding","registerAddress":0,"registerCount":2,"valueType":"float32","wordOrder":"ab","scaleFactor":0.01,"pollIntervalMs":1000}]}' \
rtk bash scripts/arm/verify_scale_protocol.sh
```

脚本会固定检查：

- `/api/scales/status` 可访问
- 运行态设备清单完整
- `driverAvailable / driverStatus / onlineDeviceCount` 合理
- 在线设备 `sampleTime` 新鲜度符合 `pollIntervalMs`
- `registerAddress / registerCount / registerArea / valueType / wordOrder / scaleFactor` 已落到当前运行态
- 如提供 `SCALE_VERIFY_EXPECTED_SPEC`，则逐字段比对期望映射

## 第三步：做三点实称校对

脚本通过后，再做真实重量核对。最少保留三组样本：

1. 空载或零点
2. 中间载荷
3. 接近常用上限的载荷

每组都记录：

- 标准重量或现场基准值
- 设备显示值
- 后端 `currentWeight`
- 绝对误差
- 相对误差

建议判定口径：

- 若现场已有厂商精度口径，优先按厂商口径
- 若现场还没有正式口径，先按“相对误差不超过 `0.5%` 或绝对误差不超过 `1` 个最小分度值”做临时验收线

## 第四步：核对采样周期与心跳

重点不是只看“有数”，而是确认节奏一致：

- `pollIntervalMs` 是否与现场要求一致
- `sampleTime` 是否持续推进
- 网络抖动或串口抖动时，`driverStatus / lastError` 是否能反映问题
- 若设备本身有心跳寄存器或状态字，需把“正常推进”和“超时/离线”语义写进记录模板

## 第五步：核对异常码语义

至少确认下面几类异常：

- 断线或掉电
- 过载或量程越界
- 稳定标志丢失
- 设备自检失败

要求：

- 异常码原始值
- 设备原始语义
- 当前系统中应映射成的业务语义
- 当前后端或前端是否已有可见留痕

如果当前后端还没有直接暴露异常码，不要伪造“已完成”，而是在记录模板里注明“设备原始语义已确认，系统展示仍待后续接入”。

## 通过标准

本轮可以把“称重协议核对”标成通过，至少要同时满足：

- `verify_scale_protocol.sh` 返回 `PASS`
- 现场寄存器映射与 `ui/scale_devices` 一致
- 三组样本称重点误差在当前验收线内
- 采样周期与心跳节奏可解释
- 异常码语义已经回写到记录模板

## 回写要求

完成后同时回写：

1. [`称重设备协议验收记录模板`](称重设备协议验收记录模板.md)
2. `todo.md`
3. [`项目完成状态说明`](项目完成状态说明.md)
4. 必要时补到设备 README 或现场联调记录
