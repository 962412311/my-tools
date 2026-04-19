# 点云现场算法总览 README

> 文档定位说明：本文档主要解释现场点云算法链的目标、约束和对象关系，不作为现行部署步骤、WebSocket 协议字段或配置中心操作手册；相关执行口径请优先看 `docs/system-architecture.md`、`docs/gogs-rtk.md` 与当前源码。

## 目标

这份文档不是重复展开某一段实现细节，而是把当前仓库里已经形成的点云主链、盲区补偿、低置信度补扫、轨迹融合和现场诊断放到同一张图里，说明它们在真实现场里是怎么协同工作的。

当前项目的算法目标可以概括为三件事：

1. 最高点要稳，不能因为中心盲区和瞬时噪声把控制链路带偏
2. 体积要尽量接近真实料堆表面，优先利用慢速扫描形成的历史覆盖
3. 当局部置信度不足时，要能明确告诉现场“为什么不足”，而不是只给一个黑箱结果

## 当前现场约束

当前算法链路是围绕固定现场条件设计的：

- 雷达垂直朝下
- 料堆在抓斗行车慢速扫描过程中逐步被覆盖
- 单帧点云稀疏，真正有效的信息来自连续移动过程中的多帧重叠
- 中心盲区是常态，不是异常
- 现场更关注“保守稳定”和“可回看诊断”，不是大而全的三维重建

因此，算法不是按“单帧点云 -> 直接输出结果”设计的，而是按“连续轨迹 -> 表面图 -> 体积/最高点/诊断”的方式组织。

## 总体链路

```text
雷达点云 / PLC 位姿
        |
        v
原始过滤链
        |
        v
短轨迹窗口融合
        |
        v
区域表面网格更新
        |
        +--> 最高点检测
        +--> 体积估算
        +--> 盲区补偿
        +--> 低置信度补扫建议
        +--> 处理诊断输出
```

当前对应实现位置：

- `backend/src/processing/pcl/PointCloudProcessor.cpp`
- `backend/src/processing/pcl/GlobalMapManager.cpp`
- `backend/src/processing/pcl/VolumeCalculator.cpp`
- `backend/src/service/RescanCoordinator.cpp`
- `backend/src/service/HttpServer.cpp`

## 算法分层

### 1. 观测层

这一层只回答“当前看到了什么”：

- 原始点云是否有效
- PLC 位姿是否有效
- 点云是否落在当前 ROI 内
- 最高点是否有稳定可见样本
- 环形可视域内是否存在足够样本

这一层不直接做业务决策，只把观测事实交给后续链路。

### 2. 表面层

这一层只维护料堆表面，不维护实体体素：

- 通过短轨迹窗口把连续移动过程中的多帧点云融合成轨迹块
- 把轨迹块按世界坐标更新到二维表面单元
- 对 `z_mean`、`z_top`、候选高点和置信度做增量融合

这层的核心意义是：

- 让“慢速扫描”的多帧重叠真正进入结果
- 让表面保持可解释、可回看、可调参

### 3. 估算层

这一层输出业务结果：

- 最高点
- 体积
- 表面覆盖质量
- 盲区补偿程度
- 是否建议补扫

估算层不应该绕过表面层直接对单帧做硬推断。

### 4. 调度层

这一层处理“要不要动、能不能动、什么时候动”：

- 判断是否建议补扫
- 判断是否允许自动执行
- 处理控制会话和优先级互斥
- 处理补扫 preview 与真实执行的分界

当前这层由 `RescanCoordinator` 承接。

### 5. 展示层

前端只负责：

- 展示诊断结果
- 展示回放与联动状态
- 展示补扫建议和阻塞原因
- 提供人工可控的入口

前端不直接解释复杂算法细节。

## 现场算法主线

### 主线 A：稳定表面与体积

1. 雷达点云和 PLC 位姿进入 `PointCloudProcessor`
2. 自适应边界、ROI、离群点和时序过滤清洗原始数据
3. 连续慢速扫描形成短轨迹窗口
4. `GlobalMapManager` 更新区域表面单元
5. `VolumeCalculator` 优先使用融合表面图计算体积
6. 若中心盲区仍有缺口，再做保守补偿
7. 输出 `volumeSource / volumeBlindZoneSupportRatio / volumeCompensatedCells` 等诊断字段

### 主线 B：最高点与控制安全

1. 最高点直接来自可见高置信度样本
2. 如果当前 ROI 没有稳定样本，最高点必须无效
3. PLC 写回前必须先判断有效性
4. 最高点是控制量，不是展示量，宁可保守，不可凭空外推

### 主线 C：低置信度主动补扫

1. `PointCloudProcessor` 先产生低置信度诊断
2. `RescanCoordinator` 汇总为建议状态
3. 前端展示 `rescanSuggested / blockedReason / suggestedTarget`
4. 满足控制条件后才允许真实执行
5. 执行结束后回写是否真正改善了最高点和盲区支撑率

这条链路的关键不是“自动转圈找数据”，而是：

- 明确阻塞原因
- 明确建议目标位姿
- 明确 preview / live 的边界

## 轨迹窗口与表面更新

短轨迹窗口的作用是把连续移动中的稀疏帧先压成块，再更新表面。

当前触发和结算的判断主要看：

- 累积位移
- 累积时长
- 帧数上限
- 停止过渡
- 方向变化

现场对应的诊断结果包括：

- `direction_change`
- `distance_or_time`
- `stopped`
- `stationary`
- `stop_empty`

它们的意义不是“程序状态码”，而是现场判断这次表面更新为什么分块的依据。

## 盲区补偿与低置信度的关系

这两者经常会被混在一起，但它们解决的问题不同：

- 盲区补偿解决“当前表面图已经有了，但中心区域仍然系统性偏低”
- 低置信度补扫解决“当前观测条件本身就不够好，需要换一个位置再采一遍”

因此：

- 盲区补偿是结果修正
- 主动补扫是观测条件修正

现场联调时应优先看：

- 是否有稳定慢速扫描覆盖
- 是否只是中心盲区偏低
- 是否整块 ROI 都长期缺样本

如果只是中心盲区偏低，优先调补偿参数；如果是整块置信度都低，优先考虑补扫。

## 现场判断顺序

现场遇到问题时，建议按这个顺序排查：

1. 先看 `PointCloudProcessor` 诊断
2. 再看 `GlobalMapManager` 表面是否持续更新
3. 再看 `VolumeCalculator` 体积是否来自 `surface-map`
4. 再看 `RescanCoordinator` 是否只在建议态，还是已进入执行态
5. 最后看前端页面是否正确反映了真实状态

不要一上来就从前端 UI 猜算法坏了，大多数问题会先体现在诊断字段里。

## 现场联调顺序

如果是第一次看现场联调，建议按下面顺序做：

1. 先确认 PLC 位姿和远控状态是否稳定
2. 再确认最高点、轨迹窗口和表面单元是否按预期更新
3. 然后看盲区补偿的支撑率和补偿量是否符合当前料堆形态
4. 最后才看低置信度补扫是不是只停留在建议态，或者已经能进入受控执行

这个顺序的目的，是先确认“基础观测是否可靠”，再确认“修正是否合理”，最后再确认“主动补扫是否需要”。

## 现场场景矩阵

### 1. 行车持续慢速扫描

预期：

- 短轨迹窗口持续结算
- 表面单元逐步增密
- 体积优先走融合表面图
- 最高点保持稳定

### 2. 行车短暂停顿

预期：

- 最后一帧并入窗口后收尾
- 不强行补密
- 表面图不会因为停止而突然跳变

### 3. 方向变化

预期：

- 轨迹窗口提前切块
- 新方向形成新的轨迹块
- 诊断中的 `direction_change` 可回显

### 4. 中心盲区偏大

预期：

- `volumeBlindZoneSupportRatio` 下降
- 补偿体积增加
- 最高点未必变化
- 如果连续偏低，需要考虑主动补扫建议

### 5. 局部置信度长期不足

预期：

- `rescanSuggested` 变为 true
- `rescanSuggestedReason` 给出明确原因
- 若控制条件不满足，只能停留在建议态

### 6. 最高点无效

预期：

- 不回写虚假最高点
- 前端提示原因
- 若连续出现，应优先检查视域和姿态，而不是粗暴改阈值

## 当前已落地的诊断入口

现场已经可以直接看的字段主要包括：

- `trajectoryFlushReason`
- `trajectoryWindowActive`
- `trajectoryWindowFrames`
- `trajectoryWindowDistance`
- `surfaceCellCount`
- `volumeSource`
- `volumeBlindZoneSupportRatio`
- `volumeBlindZoneCompensation`
- `rescanSuggested`
- `rescanSuggestedReason`
- `rescanSuggestionConsecutiveFrames`
- `rescanSuggestionCount`
- `rescanCooldownRemainingFrames`

这些字段已经足够支撑现场把“扫到了、没扫到、补偿了、建议补扫了”区分开。
其中 `volumeBlindZoneSupportRatio` 现在同时反映扇区覆盖和环带样本密度，并按环带厚度归一化，慢速扫描时如果每个扇区只有零星样本，仍应优先视为支撑不足。
如果需要进一步判断问题源头，再看：

- `volumeBlindZoneCoverageRatio`，判断是不是覆盖扇区不够
- `volumeBlindZoneDensityRatio`，判断是不是已覆盖扇区里的样本密度不够

## 现场决策树

现场如果只看一眼结果，不知道下一步怎么判断，可以直接按下面顺序走：

1. 最高点异常
   - 先看 `highestPointValid`
   - 再看 `highestPointCandidateCount`
   - 若候选点也少，优先查视域、姿态和 ROI，不要先调补偿参数
2. 体积偏低
   - 先看 `volumeSource`
   - 若已是 `surface-map`，再看 `volumeBlindZoneSupportRatio`
   - 如果支撑率低，再拆看 `volumeBlindZoneCoverageRatio` 和 `volumeBlindZoneDensityRatio`
   - 若支撑率低，优先查轨迹覆盖和慢速扫描重叠
3. 体积偶发虚高
   - 先看 `volumeBlindZoneCompensation`
   - 再看 `blindZoneAnnulusThicknessFactor` 和 `blindZoneHeightQuantile`
   - 若补偿面积和分位数都偏激进，优先收保守参数
4. 长期局部缺样本
   - 先看 `rescanSuggested`
   - 再看 `rescanSuggestedReason`
   - 若阻塞原因是控制占用或安全态，就先处理控制链路，不要强行执行补扫
5. 轨迹切块异常
   - 先看 `trajectoryFlushReason`
   - 再看 `trajectoryWindowFrames / trajectoryWindowDistance`
   - 若长时间不切块或频繁切块，优先检查方向阈值和位姿连续性

## 字段对照表

| 现场现象 | 优先字段 | 直接含义 | 下一步 |
| --- | --- | --- | --- |
| 最高点显示无效 | `highestPointValid` | 当前没有可靠最高点 | 查视域、ROI、姿态 |
| 体积比历史明显偏低 | `volumeSource` / `volumeBlindZoneSupportRatio` | 是否仍在单帧回退或盲区支撑不足 | 查轨迹覆盖和补偿参数 |
| 体积偶发高跳 | `volumeBlindZoneCompensation` | 盲区补偿可能过激进 | 收环厚或分位数 |
| 料堆中心长期空洞 | `blindZoneRejectedPoints` / `volumeBlindZoneSupportRatio` | 中心盲区样本不足 | 优先看慢速扫描重叠 |
| 补扫一直只建议不执行 | `rescanSuggestedReason` / `blockedReason` | 控制或安全条件不满足 | 先处理互斥条件 |
| 轨迹窗口不稳定 | `trajectoryFlushReason` | 切块原因不符合预期 | 查位姿连续性和方向阈值 |

## 现场优先级

当前的算法与控制优先级可以简单理解为：

1. 安全状态
2. 人工/远控会话
3. 正式作业
4. 主动补扫

所有算法建议都要服从这个顺序。

## 建议保留的边界

当前阶段不建议过早做：

- 通用路径规划
- 多目标最优补扫
- 泛化到所有雷达和 PLC 组合的插件化策略
- 复杂的三维实体重建

原因很直接：

- 现场目标是稳定闭环，不是理论完美
- 当前链路已经能支撑主线业务
- 后续再按真实场景做增量优化更稳妥

## 相关文档

- [点云算法设计 README](点云算法设计README.md)
- [点云表面层轨迹融合设计说明](点云表面层轨迹融合设计说明.md)
- [低置信度主动补扫 README](低置信度主动补扫README.md)
- [现场联调验收 README](现场联调验收README.md)
- [后端服务架构 README](后端服务架构README.md)

## 现场记录建议

现场联调时，建议优先把下面三类信息写回记录模板：

1. 最高点与轨迹窗口
   - `highestPointValid`
   - `highestPointCandidateCount`
   - `trajectoryFlushReason`
   - `trajectoryWindowFrames`
   - `trajectoryWindowDistance`
2. 盲区补偿
   - `volumeSource`
   - `volumeBlindZoneSupportRatio`
   - `volumeBlindZoneCompensation`
   - `blindZoneAnnulusThicknessFactor`
   - `blindZoneHeightQuantile`
3. 低置信度补扫
   - `rescanSuggested`
   - `rescanSuggestedReason`
   - `blockedReason`
   - `suggestedTarget`
   - `controlPhase`

这三块写清楚后，基本就能把问题定位到“轨迹、体积、补偿还是补扫”。
