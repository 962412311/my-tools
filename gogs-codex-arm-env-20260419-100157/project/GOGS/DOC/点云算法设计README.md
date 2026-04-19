# 点云算法设计 README

> 先看 [点云现场算法总览 README](点云现场算法总览README.md)，再看本页的算法细节。

## 目标

点云算法主链围绕抓斗行车场景做了三个约束：

- 最高点检测要贴近真实可见点，不凭空外推
- 体积估算要尽量利用慢速扫描过程中的历史覆盖，避免中心盲区导致系统性低估
- 诊断信息要可回看，方便现场排查“是没扫到，还是确实没料”

## 现场几何假设

- 雷达安装方向：垂直朝下
- 静态可视域：不是实心圆，而是存在中心盲区的环形有效观测区
- 盲区半径模型：

```text
blindRadius = pose.z * tan(blindConeDeg)
```

默认配置：

- `blindConeDeg = 45`
- `processing/ring_visibility_filter_enabled = true`
- `processing/lidar_max_visible_radius = 0`，表示自动使用当前 ROI 半对角

## 主处理链

当前 `PointCloudProcessor` 的主流程如下：

1. 读取 PLC 位姿
2. 完成雷达点云到世界坐标的外参变换
3. 执行自适应帧边界、时间边界和环形可视域过滤
4. 用过滤后的高置信度可见点做最高点检测
5. 用融合表面图优先做体积估算
6. 若中心盲区在当前 ROI 内仍有残缺，则做保守补偿

## 最高点策略

最高点不对盲区中心做凭空插值。

当前语义是：

- 最高点高度直接取过滤链后高置信度可见点的 `z`
- 若 ROI 内没有有效可见点，则最高点无效
- PLC 写最高点前必须满足 `point.valid == true`

这样做的原因是最高点属于实时控制量，宁可保守，也不要用推测值污染控制链路。

## 体积估算策略

### 1. 融合表面图优先

在现场工况下，行车会缓慢移动经过料堆中心，因此中心盲区虽然单帧不可见，但通常会被前后帧的环形扫描区覆盖。

所以体积估算优先使用：

- `GlobalMapManager` 融合后的表面图

而不是：

- 当前单帧可见环带点云直接积分

这样可以优先消费真实历史覆盖，而不是把“慢速扫描得到的信息”丢掉。

### 2. 中心盲区保守补偿

如果融合表面图在当前 ROI 中心盲区仍有空洞，`VolumeCalculator` 会对盲区内缺失栅格做保守补偿：

1. 取盲区外一圈样本带
2. 按角度分桶收集高度
3. 每个桶取低分位高度
4. 用该低分位高度填补对应方向上的盲区空格

当前策略刻意偏保守：

- 目标是修正系统性低估
- 不追求恢复尖峰
- 不允许补偿值超过外圈样本上界

现场调参时的经验范围：

- `processing/blind_zone_annulus_thickness_factor` 先从 `2.0` 到 `4.0` 之间试
- `processing/blind_zone_height_quantile` 先从 `0.20` 到 `0.35` 之间试
- 若 `volumeBlindZoneSupportRatio` 长期偏低，优先检查慢速扫描覆盖，而不是继续把分位数往上抬
- 若体积曲线偶发抖高，优先降低分位数或缩小环厚，而不是放大补偿面积
- 盲区补偿要看“有无样本、样本覆盖、分位数”三件事，不要只看最终体积一个数字
- 如果环厚拉大后 `blindZoneSupportRatio` 提升但体积波动没有变小，说明现场更可能缺少稳定重叠，而不是补偿参数太小
- `volumeBlindZoneSupportRatio` 现在综合扇区覆盖和环带样本密度，并按环带厚度归一化，慢速扫描里单点落扇区不应被当作充分支撑
- `volumeBlindZoneCoverageRatio` 可以直接看出盲区外圈到底覆盖了多少扇区
- `volumeBlindZoneDensityRatio` 可以直接看出已覆盖扇区里的样本密度是否足够
- `confidence` 会随盲区覆盖率和样本密度一起下降，覆盖越差或密度越低，体积结果越不应被当作高置信度

## 诊断字段

当前与环形可视域和盲区补偿直接相关的诊断字段包括：

- `blindZoneRadius`
- `blindZoneAnnulusThicknessFactor`
- `blindZoneHeightQuantile`
- `ringVisiblePoints`
- `blindZoneRejectedPoints`
- `outerRangeRejectedPoints`
- `volumeSource`
- `volumeCompensatedCells`
- `volumeBlindZoneCompensation`
- `volumeBlindZoneCoverageRatio`
- `volumeBlindZoneDensityRatio`
- `volumeBlindZoneSupportRatio`

其中：

- `volumeSource = surface-map` 表示本次体积来自融合表面图
- `volumeSource = frame` 表示当前只能退回单帧点云

## 关键配置项

- `processing/ring_visibility_filter_enabled`
- `processing/lidar_blind_cone_deg`
- `processing/lidar_max_visible_radius`
- `processing/blind_zone_annulus_thickness_factor`
- `processing/blind_zone_height_quantile`
- `processing/voxel_size`
- `processing/roi_width`
- `processing/roi_height`

## 当前限制

- 盲区补偿参数仍需要在真实料堆慢速扫描场景下继续联调
- 当前补偿只针对中心盲区，不处理更远距离的稀疏遮挡问题
- 体积链路仍以保守稳定为优先，不以单帧峰值恢复为目标

## 代码位置

- `backend/src/processing/pcl/PointCloudProcessor.cpp`
- `backend/src/processing/pcl/PointCloudProcessingUtils.cpp`
- `backend/src/processing/pcl/VolumeCalculator.cpp`
- `backend/src/processing/pcl/GlobalMapManager.cpp`
- `backend/tests/pcl_regression_tests.cpp`
