# Config Center Industrialization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the frontend config center into a mature industrial configuration workbench with consistent page structure, no placeholder pages, and clear domain/task separation.

**Architecture:** Keep the existing four-domain route tree and backend API contracts, but strengthen the config-center layout primitives and refit every config page into a consistent workbench model: summary, context, work area, and risk/verification guidance. Reuse existing business components where possible, but stop treating wrapper pages as empty shells.

**Tech Stack:** Vue 3 (`<script setup>`), Vue Router 4, Element Plus, Pinia, Vite, Node built-in test runner

---

## File Map

### Existing files to modify

- `frontend/src/components/config-center/ConfigPageShell.vue`
  Responsibility: become the standard config page frame with summary/info/risk slots.
- `frontend/src/views/config/ConfigDomainLayout.vue`
  Responsibility: become a stable domain workbench layout and remove placeholder behavior.
- `frontend/src/views/config/RuntimeConfigView.vue`
  Responsibility: turn runtime config from schema-card list into a proper grouped workbench.
- `frontend/src/views/config/ScheduleStrategyView.vue`
  Responsibility: add summary/context/risk framing around inventory schedules.
- `frontend/src/views/config/AlgorithmPresetView.vue`
  Responsibility: present presets as a guided strategy page rather than a raw internal jump page.
- `frontend/src/views/config/ConfigChangeLogView.vue`
  Responsibility: add summary and audit context.
- `frontend/src/views/config/PlcConfigView.vue`
  Responsibility: add mapping summary, risk explanation, and verification guidance.
- `frontend/src/views/config/ScaleDeviceView.vue`
  Responsibility: add device summary and validation guidance.
- `frontend/src/views/config/CameraLidarAccessView.vue`
  Responsibility: group filtered schema entries by access domain and expose operational context.
- `frontend/src/views/config/DiagnosticsView.vue`
  Responsibility: replace current thin page with a real diagnostics workbench.
- `frontend/src/views/config/MaterialsView.vue`
  Responsibility: add baseline summary and business impact context.
- `frontend/src/views/config/PilesZonesView.vue`
  Responsibility: upgrade from a flat table to a mature model overview page.
- `frontend/src/views/config/CalibrationView.vue`
  Responsibility: convert from transitional parameter page into process-plus-parameter calibration workbench.
- `frontend/src/views/config/BusinessRulesView.vue`
  Responsibility: replace placeholder copy with a real rules landing/workbench page.
- `frontend/src/views/config/MaintenanceView.vue`
  Responsibility: strengthen action-card framing and execution guidance.
- `frontend/src/views/config/ExpertParamsView.vue`
  Responsibility: group expert params and isolate high-impact engineering settings.
- `frontend/src/views/UserManagementView.vue`
  Responsibility: keep the existing user management table while integrating config-domain context.
- `frontend/src/views/config/configCenterMeta.js`
  Responsibility: keep domain labels/notes aligned with the mature workbench structure.
- `frontend/tests/config-center-domain-contract.test.mjs`
  Responsibility: protect shared primitive contracts and domain page structure.
- `frontend/tests/config-center-page-contract.test.mjs`
  Responsibility: protect mature page structure on key config pages.

### New files to create

- `frontend/src/components/config-center/ConfigSectionBlock.vue`
  Responsibility: reusable titled section block for config workbench pages.
- `frontend/src/components/config-center/ConfigInfoPanel.vue`
  Responsibility: reusable context/verification/risk panel.
- `frontend/src/components/config-center/ConfigActionCard.vue`
  Responsibility: reusable action card for maintenance and other high-risk operations.

## Task 1: Lock The Mature Config Page Skeleton With Failing Tests

**Files:**
- Modify: `frontend/tests/config-center-domain-contract.test.mjs`
- Modify: `frontend/tests/config-center-page-contract.test.mjs`
- Modify later: `frontend/src/components/config-center/ConfigPageShell.vue`
- Create later: `frontend/src/components/config-center/ConfigSectionBlock.vue`
- Create later: `frontend/src/components/config-center/ConfigInfoPanel.vue`
- Create later: `frontend/src/components/config-center/ConfigActionCard.vue`

- [ ] **Step 1: Extend the config-center primitive contract test**

```js
test('config page shell exposes summary, info, default, and risk slots', () => {
  assert.match(configPageShellSource, /<slot name="summary"/)
  assert.match(configPageShellSource, /<slot name="info"/)
  assert.match(configPageShellSource, /<slot \/>/)
  assert.match(configPageShellSource, /<slot name="risk"/)
})
```

- [ ] **Step 2: Add file-level contract tests for the new reusable section primitives**

```js
const configSectionBlockSource = readFileSync(new URL('../src/components/config-center/ConfigSectionBlock.vue', import.meta.url), 'utf8')
const configInfoPanelSource = readFileSync(new URL('../src/components/config-center/ConfigInfoPanel.vue', import.meta.url), 'utf8')
const configActionCardSource = readFileSync(new URL('../src/components/config-center/ConfigActionCard.vue', import.meta.url), 'utf8')

test('new config-center section primitives exist with expected props and slots', () => {
  assert.match(configSectionBlockSource, /defineProps\(/)
  assert.match(configSectionBlockSource, /title/)
  assert.match(configSectionBlockSource, /description/)

  assert.match(configInfoPanelSource, /defineProps\(/)
  assert.match(configInfoPanelSource, /items/)

  assert.match(configActionCardSource, /defineProps\(/)
  assert.match(configActionCardSource, /tone/)
  assert.match(configActionCardSource, /<slot name="actions"/)
})
```

- [ ] **Step 3: Add page contract tests that describe the mature workbench structure**

```js
test('business and calibration pages no longer expose placeholder or transitional copy', () => {
  assert.doesNotMatch(businessRulesViewSource, /固定落点已经保留/)
  assert.doesNotMatch(calibrationViewSource, /后续再继续拆出完整采样流程/)
})

test('unfinished config pages expose summary or info panels instead of naked content', () => {
  assert.match(scheduleViewSource, /ConfigQuickStatus|ConfigInfoPanel/)
  assert.match(plcViewSource, /ConfigQuickStatus|ConfigInfoPanel/)
  assert.match(materialsViewSource, /ConfigQuickStatus|ConfigInfoPanel/)
  assert.match(expertViewSource, /ConfigQuickStatus|ConfigInfoPanel/)
})
```

- [ ] **Step 4: Run the focused config-center tests to verify they fail**

Run: `rtk npm test -- config-center-domain-contract.test.mjs config-center-page-contract.test.mjs`  
Expected: FAIL because the new slots/components do not exist and the old pages still expose transitional structures.

- [ ] **Step 5: Commit**

```bash
git add frontend/tests/config-center-domain-contract.test.mjs frontend/tests/config-center-page-contract.test.mjs
git commit -m "test: define industrial config-center page contracts"
```

## Task 2: Implement Shared Workbench Primitives And Clean Domain Layout

**Files:**
- Create: `frontend/src/components/config-center/ConfigSectionBlock.vue`
- Create: `frontend/src/components/config-center/ConfigInfoPanel.vue`
- Create: `frontend/src/components/config-center/ConfigActionCard.vue`
- Modify: `frontend/src/components/config-center/ConfigPageShell.vue`
- Modify: `frontend/src/views/config/ConfigDomainLayout.vue`
- Test: `frontend/tests/config-center-domain-contract.test.mjs`

- [ ] **Step 1: Create `ConfigSectionBlock.vue`**

```vue
<template>
  <section class="config-section-block app-panel">
    <header class="config-section-block__header">
      <div class="config-section-block__heading">
        <p v-if="eyebrow" class="config-section-block__eyebrow">{{ eyebrow }}</p>
        <h3 class="config-section-block__title">{{ title }}</h3>
        <p v-if="description" class="config-section-block__description">{{ description }}</p>
      </div>
      <div v-if="$slots.actions" class="config-section-block__actions">
        <slot name="actions" />
      </div>
    </header>
    <div class="config-section-block__body">
      <slot />
    </div>
  </section>
</template>
```

- [ ] **Step 2: Create `ConfigInfoPanel.vue`**

```vue
<template>
  <section class="config-info-panel">
    <article v-for="item in items" :key="item.label" class="config-info-panel__item" :class="item.tone ? `is-${item.tone}` : ''">
      <span class="config-info-panel__label">{{ item.label }}</span>
      <strong class="config-info-panel__value">{{ item.value }}</strong>
      <p v-if="item.description" class="config-info-panel__description">{{ item.description }}</p>
    </article>
  </section>
</template>
```

- [ ] **Step 3: Create `ConfigActionCard.vue`**

```vue
<template>
  <article class="config-action-card" :class="tone ? `is-${tone}` : ''">
    <div class="config-action-card__copy">
      <p v-if="eyebrow" class="config-action-card__eyebrow">{{ eyebrow }}</p>
      <h3 class="config-action-card__title">{{ title }}</h3>
      <p class="config-action-card__description">{{ description }}</p>
    </div>
    <ul v-if="checks.length" class="config-action-card__checks">
      <li v-for="item in checks" :key="item">{{ item }}</li>
    </ul>
    <div v-if="$slots.actions" class="config-action-card__actions">
      <slot name="actions" />
    </div>
  </article>
</template>
```

- [ ] **Step 4: Upgrade `ConfigPageShell.vue` into a full workbench frame**

```vue
<template>
  <section class="config-page-shell app-panel">
    <header class="config-page-shell__header">
      ...
    </header>

    <div v-if="$slots.summary" class="config-page-shell__summary">
      <slot name="summary" />
    </div>

    <div v-if="$slots.info" class="config-page-shell__info">
      <slot name="info" />
    </div>

    <div class="config-page-shell__body">
      <slot />
    </div>

    <div v-if="$slots.risk" class="config-page-shell__risk">
      <slot name="risk" />
    </div>
  </section>
</template>
```

- [ ] **Step 5: Remove placeholder behavior from `ConfigDomainLayout.vue`**

```vue
<div class="config-domain__content">
  <RouterView />
</div>
```

Also delete the `Component`-empty placeholder branch and the placeholder CSS block.

- [ ] **Step 6: Run the shared-layout tests to verify they pass**

Run: `rtk npm test -- config-center-domain-contract.test.mjs`  
Expected: PASS with the new shared primitive and shell assertions green.

- [ ] **Step 7: Commit**

```bash
git add frontend/src/components/config-center/ConfigPageShell.vue frontend/src/components/config-center/ConfigSectionBlock.vue frontend/src/components/config-center/ConfigInfoPanel.vue frontend/src/components/config-center/ConfigActionCard.vue frontend/src/views/config/ConfigDomainLayout.vue frontend/tests/config-center-domain-contract.test.mjs
git commit -m "feat: add industrial config workbench primitives"
```

## Task 3: Finish The Unfinished Business And Diagnostics Pages

**Files:**
- Modify: `frontend/src/views/config/BusinessRulesView.vue`
- Modify: `frontend/src/views/config/PilesZonesView.vue`
- Modify: `frontend/src/views/config/CalibrationView.vue`
- Modify: `frontend/src/views/config/DiagnosticsView.vue`
- Test: `frontend/tests/config-center-page-contract.test.mjs`

- [ ] **Step 1: Add a failing test for real workbench structure on unfinished pages**

```js
const businessRulesViewSource = readFileSync(new URL('../src/views/config/BusinessRulesView.vue', import.meta.url), 'utf8')
const pilesZonesViewSource = readFileSync(new URL('../src/views/config/PilesZonesView.vue', import.meta.url), 'utf8')
const diagnosticsViewSource = readFileSync(new URL('../src/views/config/DiagnosticsView.vue', import.meta.url), 'utf8')

test('business, piles, calibration, and diagnostics pages expose mature workbench sections', () => {
  assert.match(businessRulesViewSource, /ConfigSectionBlock/)
  assert.match(businessRulesViewSource, /ConfigInfoPanel/)
  assert.match(pilesZonesViewSource, /ConfigQuickStatus/)
  assert.match(calibrationViewSource, /ConfigInfoPanel/)
  assert.match(diagnosticsViewSource, /ConfigSectionBlock/)
})
```

- [ ] **Step 2: Run the focused page contract test and verify red**

Run: `rtk npm test -- config-center-page-contract.test.mjs`  
Expected: FAIL because the unfinished pages still use placeholder or thin layouts.

- [ ] **Step 3: Replace `BusinessRulesView.vue` placeholder copy with a real rules workbench**

```vue
<ConfigPageShell ...>
  <template #summary>
    <ConfigQuickStatus :items="statusItems" />
  </template>
  <template #info>
    <ConfigInfoPanel :items="infoItems" />
  </template>

  <ConfigSectionBlock
    title="当前规则落点"
    description="先把现有运行策略、换算口径和默认行为归类，后续新规则统一落在这一域。"
  >
    <el-table :data="ruleCategories" stripe>...</el-table>
  </ConfigSectionBlock>
</ConfigPageShell>
```

- [ ] **Step 4: Upgrade `PilesZonesView.vue` into a model overview page**

```vue
<ConfigPageShell ...>
  <template #summary>
    <ConfigQuickStatus :items="statusItems" />
  </template>
  <template #info>
    <ConfigInfoPanel :items="infoItems" />
  </template>

  <ConfigSectionBlock title="料堆清单" description="查看当前业务模型中的料堆和区域归属。">
    <el-table :data="piles" stripe>...</el-table>
  </ConfigSectionBlock>
</ConfigPageShell>
```

- [ ] **Step 5: Upgrade `CalibrationView.vue` into process-plus-parameter layout**

```vue
<template #info>
  <ConfigInfoPanel :items="processItems" />
</template>

<ConfigSectionBlock title="校准步骤" description="参数保存前先核对操作条件和采样顺序。">
  <ol class="calibration-steps">
    <li>确认设备在线和测区稳定</li>
    <li>核对基准点与雷达安装位置</li>
    <li>保存参数后执行现场复核</li>
  </ol>
</ConfigSectionBlock>
```

- [ ] **Step 6: Replace `DiagnosticsView.vue` with a true diagnostics workbench**

```vue
<ConfigPageShell ...>
  <template #summary>
    <ConfigQuickStatus :items="statusItems" />
  </template>

  <ConfigSectionBlock title="服务与链路检查" description="用于判断服务、驱动和关键端口是否处于可用状态。">
    <el-table :data="diagnosticRows" stripe>...</el-table>
  </ConfigSectionBlock>

  <template #risk>
    <ConfigInfoPanel :items="riskItems" />
  </template>
</ConfigPageShell>
```

- [ ] **Step 7: Run the page contract test to verify green**

Run: `rtk npm test -- config-center-page-contract.test.mjs`  
Expected: PASS for the unfinished-page layout assertions.

- [ ] **Step 8: Commit**

```bash
git add frontend/src/views/config/BusinessRulesView.vue frontend/src/views/config/PilesZonesView.vue frontend/src/views/config/CalibrationView.vue frontend/src/views/config/DiagnosticsView.vue frontend/tests/config-center-page-contract.test.mjs
git commit -m "feat: finish incomplete config workbench pages"
```

## Task 4: Mature The Wrapper Pages Around Existing Feature Modules

**Files:**
- Modify: `frontend/src/views/config/ScheduleStrategyView.vue`
- Modify: `frontend/src/views/config/PlcConfigView.vue`
- Modify: `frontend/src/views/config/ScaleDeviceView.vue`
- Modify: `frontend/src/views/config/MaterialsView.vue`
- Modify: `frontend/src/views/config/ConfigChangeLogView.vue`
- Modify: `frontend/src/views/config/MaintenanceView.vue`
- Modify: `frontend/src/views/UserManagementView.vue`
- Test: `frontend/tests/config-center-page-contract.test.mjs`

- [ ] **Step 1: Add failing tests for wrapper pages that must expose summary/info/risk structure**

```js
test('module-wrapper pages expose industrial workbench framing around legacy components', () => {
  assert.match(scheduleViewSource, /<template #summary>/)
  assert.match(scheduleViewSource, /ConfigInfoPanel/)
  assert.match(plcViewSource, /ConfigInfoPanel/)
  assert.match(scaleViewSource, /ConfigQuickStatus/)
  assert.match(materialsViewSource, /ConfigQuickStatus/)
  assert.match(changeLogViewSource, /ConfigQuickStatus/)
  assert.match(maintenanceViewSource, /ConfigActionCard/)
})
```

- [ ] **Step 2: Run the config page contract test and verify red**

Run: `rtk npm test -- config-center-page-contract.test.mjs`  
Expected: FAIL because these pages still act as thin wrappers.

- [ ] **Step 3: Add workbench framing to `ScheduleStrategyView.vue`, `PlcConfigView.vue`, `ScaleDeviceView.vue`, and `MaterialsView.vue`**

```vue
<template #summary>
  <ConfigQuickStatus :items="statusItems" />
</template>
<template #info>
  <ConfigInfoPanel :items="infoItems" />
</template>
<template #risk>
  <ConfigInfoPanel :items="riskItems" />
</template>
```

Populate `statusItems`, `infoItems`, and `riskItems` from the page's loaded data rather than hard-coded placeholder numbers.

- [ ] **Step 4: Add audit framing to `ConfigChangeLogView.vue`**

```vue
<template #summary>
  <ConfigQuickStatus :items="summaryItems" />
</template>
<template #info>
  <ConfigInfoPanel :items="auditItems" />
</template>
```

- [ ] **Step 5: Replace the hand-rolled maintenance cards with `ConfigActionCard`**

```vue
<ConfigActionCard
  eyebrow="危险动作"
  title="重启系统"
  tone="danger"
  :checks="['当前连接会中断', '建议在盘存任务空闲窗口执行']"
>
  <template #actions>
    <el-button type="danger" :loading="loading" @click="executeAction('restart')">安排重启</el-button>
  </template>
</ConfigActionCard>
```

- [ ] **Step 6: Wrap `UserManagementView.vue` in config-domain context without rewriting the mature table**

```vue
<ConfigPageShell
  eyebrow="用户与权限"
  title="用户管理"
  description="面向管理员的账号、角色和授权边界工作台。"
>
  <template #info>
    <ConfigInfoPanel :items="permissionInfoItems" />
  </template>
  ...
</ConfigPageShell>
```

- [ ] **Step 7: Run the page contract tests to verify green**

Run: `rtk npm test -- config-center-page-contract.test.mjs`  
Expected: PASS for the wrapper-page assertions.

- [ ] **Step 8: Commit**

```bash
git add frontend/src/views/config/ScheduleStrategyView.vue frontend/src/views/config/PlcConfigView.vue frontend/src/views/config/ScaleDeviceView.vue frontend/src/views/config/MaterialsView.vue frontend/src/views/config/ConfigChangeLogView.vue frontend/src/views/config/MaintenanceView.vue frontend/src/views/UserManagementView.vue frontend/tests/config-center-page-contract.test.mjs
git commit -m "feat: mature config module wrapper pages"
```

## Task 5: Refine Schema-Driven Pages, Align Metadata, And Verify The Whole Config Center

**Files:**
- Modify: `frontend/src/views/config/RuntimeConfigView.vue`
- Modify: `frontend/src/views/config/CameraLidarAccessView.vue`
- Modify: `frontend/src/views/config/AlgorithmPresetView.vue`
- Modify: `frontend/src/views/config/ExpertParamsView.vue`
- Modify: `frontend/src/views/config/configCenterMeta.js`
- Modify: `frontend/tests/config-center-page-contract.test.mjs`
- Modify: `frontend/tests/config-center-domain-contract.test.mjs`

- [ ] **Step 1: Add failing tests for grouped schema-driven workbench behavior**

```js
test('runtime, access, and expert pages group schema items into named workbench sections', () => {
  assert.match(runtimeViewSource, /runtimeConfigGroups/)
  assert.match(runtimeViewSource, /ConfigSectionBlock|ConfigInfoPanel/)
  assert.match(accessViewSource, /groupedItems|accessGroups/)
  assert.match(expertViewSource, /groupedItems|expertGroups/)
})

test('config center metadata describes industrial workbench navigation instead of placeholders', () => {
  const metaSource = readFileSync(new URL('../src/views/config/configCenterMeta.js', import.meta.url), 'utf8')
  assert.doesNotMatch(metaSource, /placeholderTitle/)
  assert.doesNotMatch(metaSource, /placeholderDescription/)
})
```

- [ ] **Step 2: Run the route/domain/page tests and verify red**

Run: `rtk npm test -- config-center-domain-contract.test.mjs config-center-page-contract.test.mjs config-center-route-contract.test.mjs`  
Expected: FAIL because grouped-section contracts and metadata cleanup are not implemented yet.

- [ ] **Step 3: Refactor `RuntimeConfigView.vue` into a grouped workbench**

```vue
<template #summary>
  <ConfigQuickStatus :items="statusItems" />
</template>
<template #info>
  <ConfigInfoPanel :items="infoItems" />
</template>

<div class="runtime-workbench">
  <aside class="runtime-workbench__groups">...</aside>
  <div class="runtime-workbench__content">
    <ConfigSectionBlock :title="group.name" :description="groupDescription(group)">
      <div class="runtime-grid">...</div>
    </ConfigSectionBlock>
  </div>
</div>

<template #risk>
  <ConfigInfoPanel :items="riskItems" />
</template>
```

- [ ] **Step 4: Refactor `CameraLidarAccessView.vue` and `ExpertParamsView.vue` to group filtered schema items**

```js
const accessGroups = computed(() => ([
  { key: 'camera', title: '相机接入', items: items.value.filter((item) => item.key.startsWith('camera/')) },
  { key: 'recording', title: '录像留档', items: items.value.filter((item) => item.key.startsWith('recording/')) }
]).filter((group) => group.items.length))

const expertGroups = computed(() => {
  const groups = new Map()
  for (const item of items.value) {
    const groupName = item.group || '未分组'
    ...
  }
  return Array.from(groups.entries()).map(([name, groupItems]) => ({ name, items: groupItems }))
})
```

- [ ] **Step 5: Add summary/info/risk framing to `AlgorithmPresetView.vue` and clean `configCenterMeta.js`**

```js
delete meta.placeholderTitle
delete meta.placeholderDescription
```

Replace them with navigation copy that describes actual workbench intent only.

- [ ] **Step 6: Run the full config-center test set**

Run: `rtk npm test -- config-center-route-contract.test.mjs config-center-domain-contract.test.mjs config-center-page-contract.test.mjs auth-config-guard.test.mjs`  
Expected: PASS for all config-center contract tests.

- [ ] **Step 7: Run the frontend build**

Run: `rtk npm run build`
Expected: Vite build succeeds with exit code 0.

- [ ] **Step 8: Commit**

```bash
git add frontend/src/views/config/RuntimeConfigView.vue frontend/src/views/config/CameraLidarAccessView.vue frontend/src/views/config/AlgorithmPresetView.vue frontend/src/views/config/ExpertParamsView.vue frontend/src/views/config/configCenterMeta.js frontend/tests/config-center-page-contract.test.mjs frontend/tests/config-center-domain-contract.test.mjs
git commit -m "feat: industrialize schema-driven config workbenches"
```

## Self-Review

### Spec coverage

- Shared workbench skeleton: covered by Task 1 and Task 2
- Unfinished pages removal: covered by Task 3
- Wrapper page maturation: covered by Task 4
- Schema-driven page cleanup and metadata cleanup: covered by Task 5
- Verification and route/domain integrity: covered by Task 5

### Placeholder scan

- No `TODO` or `TBD`
- No vague “handle later” steps
- Every task has explicit files, commands, and concrete test/implementation snippets

### Type consistency

- Shared primitive names are consistent across all tasks:
  - `ConfigSectionBlock`
  - `ConfigInfoPanel`
  - `ConfigActionCard`
- Page test filenames and config route names match the current codebase

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-04-16-config-center-industrialization-implementation.md`.

用户已明确要求我自主推进，不等待额外选择。本轮默认采用 Inline Execution，在当前会话中按计划顺序实施。
