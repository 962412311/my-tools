# Config Center Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the frontend config module into a multi-route configuration center organized by task domains, while preserving existing configuration capabilities and making operations/admin workflows clearer.

**Architecture:** Replace the current single `ConfigView.vue` super-container with a configuration shell route plus 4 domain entry views and focused child pages. Reuse existing config feature modules where possible, introduce a small config-center page/layout layer, and migrate high-value pages first before retiring the old giant view.

**Tech Stack:** Vue 3 (`<script setup>`), Vue Router 4, Element Plus, Pinia, Vite, Node built-in test runner

---

## File Map

### Existing files to modify

- `frontend/src/router/index.js`
  Responsibility: split `/config` into nested routes and preserve admin/super-admin guards.
- `frontend/src/views/LayoutView.vue`
  Responsibility: continue rendering config routes cleanly in the main shell and keep sidebar highlighting correct.
- `frontend/src/views/ConfigView.vue`
  Responsibility: temporary bridge or legacy fallback during migration, then removal/simplification.
- `frontend/src/views/UserManagementView.vue`
  Responsibility: keep existing user management behavior but adapt to new advanced domain container.
- `frontend/tests/auth-config-guard.test.mjs`
  Responsibility: route/config structure contract coverage.

### New files to create

- `frontend/src/views/config/ConfigCenterView.vue`
  Responsibility: `/config` index page with 4 domain cards, summary state, and quick links.
- `frontend/src/views/config/ConfigDomainLayout.vue`
  Responsibility: shared shell for domain pages with local navigation and `router-view`.
- `frontend/src/views/config/OperationsHomeView.vue`
- `frontend/src/views/config/DevicesHomeView.vue`
- `frontend/src/views/config/BusinessHomeView.vue`
- `frontend/src/views/config/AdvancedHomeView.vue`
  Responsibility: one home page per domain.
- `frontend/src/views/config/RuntimeConfigView.vue`
  Responsibility: operations runtime page migrated from the current runtime portion of `ConfigView.vue`.
- `frontend/src/views/config/ScheduleStrategyView.vue`
  Responsibility: operations schedule page hosting `InventoryScheduleConfig`.
- `frontend/src/views/config/AlgorithmPresetView.vue`
  Responsibility: operations algorithm page hosting the non-expert algorithm entry.
- `frontend/src/views/config/DevicesOverviewView.vue`
  Responsibility: device health and completion summary.
- `frontend/src/views/config/PlcConfigView.vue`
  Responsibility: PLC workbench page hosting `PlcMappingConfig`.
- `frontend/src/views/config/ScaleDeviceView.vue`
  Responsibility: scale device page hosting `ScaleConfig`.
- `frontend/src/views/config/CameraLidarAccessView.vue`
  Responsibility: camera/lidar baseline page, initially showing current runtime-linked access guidance.
- `frontend/src/views/config/DiagnosticsView.vue`
  Responsibility: link/driver/service diagnostics page.
- `frontend/src/views/config/MaterialsView.vue`
  Responsibility: business materials page hosting `DataManageConfig`.
- `frontend/src/views/config/PilesZonesView.vue`
  Responsibility: business pile/zone baseline page.
- `frontend/src/views/config/CalibrationView.vue`
  Responsibility: business calibration workflow page migrated from `ConfigView.vue`.
- `frontend/src/views/config/SystemOverviewView.vue`
  Responsibility: advanced system overview page.
- `frontend/src/views/config/MaintenanceView.vue`
  Responsibility: advanced maintenance actions page.
- `frontend/src/views/config/ExpertParamsView.vue`
  Responsibility: advanced expert/runtime parameter page.
- `frontend/src/components/config-center/ConfigDomainHero.vue`
- `frontend/src/components/config-center/ConfigPageShell.vue`
- `frontend/src/components/config-center/ConfigQuickStatus.vue`
  Responsibility: reusable config-center shell primitives.
- `frontend/tests/config-center-route-contract.test.mjs`
- `frontend/tests/config-center-domain-contract.test.mjs`
  Responsibility: route map and page contract protection.

## Task 1: Lock New Config Route Tree With Failing Tests

**Files:**
- Create: `frontend/tests/config-center-route-contract.test.mjs`
- Modify: `frontend/tests/auth-config-guard.test.mjs`
- Modify later: `frontend/src/router/index.js`

- [ ] **Step 1: Write the failing route contract test**

```js
import test from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'

const routerSource = readFileSync(resolve('src/router/index.js'), 'utf8')

test('config center uses nested multi-route domains instead of a single config page route', () => {
  assert.match(routerSource, /path: 'config'/)
  assert.match(routerSource, /component: \(\) => import\('\.\.\/views\/config\/ConfigCenterView\.vue'\)/)
  assert.match(routerSource, /path: 'operations'/)
  assert.match(routerSource, /path: 'devices'/)
  assert.match(routerSource, /path: 'business'/)
  assert.match(routerSource, /path: 'advanced'/)
  assert.doesNotMatch(routerSource, /component: \(\) => import\('\.\.\/views\/ConfigView\.vue'\)/)
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `rtk npm test -- config-center-route-contract.test.mjs`  
Expected: FAIL because `router/index.js` still points `/config` at `ConfigView.vue`

- [ ] **Step 3: Extend existing guard test for nested admin pages**

```js
test('config routes keep admin protection at the config center root', () => {
  assert.match(routerSource, /path: 'config'[\s\S]*meta: \{[\s\S]*admin: true/)
})
```

- [ ] **Step 4: Run the focused config guard tests**

Run: `rtk npm test -- auth-config-guard.test.mjs config-center-route-contract.test.mjs`  
Expected: FAIL only on the new route contract assertions

- [ ] **Step 5: Commit**

```bash
git add frontend/tests/auth-config-guard.test.mjs frontend/tests/config-center-route-contract.test.mjs
git commit -m "test: define config center route contracts"
```

## Task 2: Introduce Config Center Shell And Nested Router

**Files:**
- Create: `frontend/src/views/config/ConfigCenterView.vue`
- Create: `frontend/src/views/config/ConfigDomainLayout.vue`
- Modify: `frontend/src/router/index.js`
- Test: `frontend/tests/config-center-route-contract.test.mjs`

- [ ] **Step 1: Create the config center index shell**

```vue
<template>
  <div class="config-center-view">
    <PageHeader
      eyebrow="系统配置"
      title="配置中心"
      description="按任务域管理运行策略、设备接入、业务基础和高级维护。"
    />
    <div class="config-center-grid">
      <RouterLink to="/config/operations">运行与策略</RouterLink>
      <RouterLink to="/config/devices">设备与链路</RouterLink>
      <RouterLink to="/config/business">业务基础</RouterLink>
      <RouterLink to="/config/advanced">高级与维护</RouterLink>
    </div>
  </div>
</template>
```

- [ ] **Step 2: Create the shared domain layout**

```vue
<template>
  <div class="config-domain-layout">
    <PageHeader :eyebrow="eyebrow" :title="title" :description="description" compact />
    <div class="config-domain-layout__body">
      <aside class="config-domain-layout__nav">
        <RouterLink
          v-for="item in items"
          :key="item.to"
          :to="item.to"
        >
          {{ item.label }}
        </RouterLink>
      </aside>
      <main class="config-domain-layout__content">
        <RouterView />
      </main>
    </div>
  </div>
</template>
```

- [ ] **Step 3: Replace `/config` single-page route with nested domain routes**

```js
{
  path: 'config',
  component: () => import('../views/config/ConfigCenterView.vue'),
  meta: { title: '配置管理', icon: 'Setting', admin: true },
  children: [
    {
      path: 'operations',
      component: () => import('../views/config/ConfigDomainLayout.vue'),
      children: []
    }
  ]
}
```

- [ ] **Step 4: Run route contract tests**

Run: `rtk npm test -- config-center-route-contract.test.mjs auth-config-guard.test.mjs`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add frontend/src/router/index.js frontend/src/views/config/ConfigCenterView.vue frontend/src/views/config/ConfigDomainLayout.vue frontend/tests/config-center-route-contract.test.mjs frontend/tests/auth-config-guard.test.mjs
git commit -m "feat: add config center shell routes"
```

## Task 3: Add Domain Entry Pages And Shared Config-Center Primitives

**Files:**
- Create: `frontend/src/components/config-center/ConfigDomainHero.vue`
- Create: `frontend/src/components/config-center/ConfigPageShell.vue`
- Create: `frontend/src/components/config-center/ConfigQuickStatus.vue`
- Create: `frontend/src/views/config/OperationsHomeView.vue`
- Create: `frontend/src/views/config/DevicesHomeView.vue`
- Create: `frontend/src/views/config/BusinessHomeView.vue`
- Create: `frontend/src/views/config/AdvancedHomeView.vue`
- Modify: `frontend/src/router/index.js`
- Test: `frontend/tests/config-center-domain-contract.test.mjs`

- [ ] **Step 1: Write the failing domain contract test**

```js
import test from 'node:test'
import assert from 'node:assert/strict'
import { readFileSync } from 'node:fs'
import { resolve } from 'node:path'

const operationsHome = readFileSync(resolve('src/views/config/OperationsHomeView.vue'), 'utf8')

test('operations home surfaces runtime, schedule, algorithm, and change log entry cards', () => {
  assert.match(operationsHome, /运行参数总览/)
  assert.match(operationsHome, /自动策略/)
  assert.match(operationsHome, /算法预设/)
  assert.match(operationsHome, /配置变更记录/)
})
```

- [ ] **Step 2: Run test to verify it fails**

Run: `rtk npm test -- config-center-domain-contract.test.mjs`  
Expected: FAIL because the domain views do not exist yet

- [ ] **Step 3: Create the shared page-shell primitives**

```vue
<template>
  <section class="config-page-shell app-panel">
    <header class="config-page-shell__header">
      <div>
        <p class="config-page-shell__eyebrow">{{ eyebrow }}</p>
        <h2>{{ title }}</h2>
        <p>{{ description }}</p>
      </div>
      <slot name="actions" />
    </header>
    <slot />
  </section>
</template>
```

- [ ] **Step 4: Create 4 domain home pages and register them as domain index children**

```js
{
  path: 'operations',
  component: () => import('../views/config/ConfigDomainLayout.vue'),
  children: [
    { path: '', component: () => import('../views/config/OperationsHomeView.vue') },
    // more children later
  ]
}
```

- [ ] **Step 5: Run the new domain tests**

Run: `rtk npm test -- config-center-domain-contract.test.mjs config-center-route-contract.test.mjs`  
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add frontend/src/components/config-center frontend/src/views/config/OperationsHomeView.vue frontend/src/views/config/DevicesHomeView.vue frontend/src/views/config/BusinessHomeView.vue frontend/src/views/config/AdvancedHomeView.vue frontend/src/router/index.js frontend/tests/config-center-domain-contract.test.mjs
git commit -m "feat: add config domain entry pages"
```

## Task 4: Migrate Operations Domain High-Value Pages

**Files:**
- Create: `frontend/src/views/config/RuntimeConfigView.vue`
- Create: `frontend/src/views/config/ScheduleStrategyView.vue`
- Create: `frontend/src/views/config/AlgorithmPresetView.vue`
- Modify: `frontend/src/views/ConfigView.vue`
- Modify: `frontend/src/router/index.js`
- Modify: `frontend/tests/auth-config-guard.test.mjs`

- [ ] **Step 1: Write a failing contract test for runtime migration**

```js
test('runtime config now lives in a dedicated operations page instead of only in ConfigView', () => {
  const runtimeViewSource = readFileSync(resolve('src/views/config/RuntimeConfigView.vue'), 'utf8')
  assert.match(runtimeViewSource, /保存全部运行参数/)
  assert.match(runtimeViewSource, /运行参数总览/)
})
```

- [ ] **Step 2: Run the focused test**

Run: `rtk npm test -- auth-config-guard.test.mjs`  
Expected: FAIL on the new runtime migration assertions

- [ ] **Step 3: Extract runtime section from `ConfigView.vue` into `RuntimeConfigView.vue`**

```vue
<template>
  <ConfigPageShell
    eyebrow="运行与策略"
    title="运行参数总览"
    description="按运维场景查看和维护系统运行参数。"
  >
    <!-- move the runtime alerts, runtime toolbar, runtime group tabs, and save bar here -->
  </ConfigPageShell>
</template>
```

- [ ] **Step 4: Host inventory schedules and algorithm preset entry in their own pages**

```vue
<InventoryScheduleConfig v-model:inventory-schedules="inventorySchedules" :pile-list="pileList" />
```

```vue
<AlgorithmConfig
  :runtime-config-schema="runtimeConfigSchema"
  :runtime-config-values="runtimeConfigValues"
  @open-runtime-group="openRuntimeGroup"
/>
```

- [ ] **Step 5: Register `/config/operations/runtime`, `/schedules`, and `/algorithm-presets` routes**

Run: `rtk npm test -- auth-config-guard.test.mjs config-center-route-contract.test.mjs`  
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add frontend/src/views/config/RuntimeConfigView.vue frontend/src/views/config/ScheduleStrategyView.vue frontend/src/views/config/AlgorithmPresetView.vue frontend/src/views/ConfigView.vue frontend/src/router/index.js frontend/tests/auth-config-guard.test.mjs
git commit -m "feat: migrate operations config pages"
```

## Task 5: Migrate Devices Domain Pages

**Files:**
- Create: `frontend/src/views/config/DevicesOverviewView.vue`
- Create: `frontend/src/views/config/PlcConfigView.vue`
- Create: `frontend/src/views/config/ScaleDeviceView.vue`
- Create: `frontend/src/views/config/CameraLidarAccessView.vue`
- Create: `frontend/src/views/config/DiagnosticsView.vue`
- Modify: `frontend/src/router/index.js`
- Modify: `frontend/src/views/ConfigView.vue`
- Test: `frontend/tests/config-center-domain-contract.test.mjs`

- [ ] **Step 1: Write failing device-domain assertions**

```js
test('devices domain exposes overview, plc, scale, camera-lidar, and diagnostics pages', () => {
  assert.match(routerSource, /devices\/overview/)
  assert.match(routerSource, /devices\/plc/)
  assert.match(routerSource, /devices\/scale/)
  assert.match(routerSource, /devices\/camera-lidar/)
  assert.match(routerSource, /devices\/diagnostics/)
})
```

- [ ] **Step 2: Run the focused device-domain test**

Run: `rtk npm test -- config-center-domain-contract.test.mjs`  
Expected: FAIL on the new device route assertions

- [ ] **Step 3: Wrap existing PLC and scale modules in dedicated page views**

```vue
<ConfigPageShell eyebrow="设备与链路" title="PLC 与寄存器映射" description="维护现场寄存器地址、读写映射和联调上下文。">
  <PlcMappingConfig />
</ConfigPageShell>
```

```vue
<ConfigPageShell eyebrow="设备与链路" title="称重设备" description="维护连接参数、运行状态和联调动作。">
  <ScaleConfig />
</ConfigPageShell>
```

- [ ] **Step 4: Add overview, camera-lidar, and diagnostics placeholder pages with real current-state data sources**

```vue
<ConfigQuickStatus label="称重驱动" :status="maintenanceStatus.scaleDriverAvailable ? 'ok' : 'error'" />
```

- [ ] **Step 5: Run route and domain tests**

Run: `rtk npm test -- config-center-domain-contract.test.mjs config-center-route-contract.test.mjs`  
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add frontend/src/views/config/DevicesOverviewView.vue frontend/src/views/config/PlcConfigView.vue frontend/src/views/config/ScaleDeviceView.vue frontend/src/views/config/CameraLidarAccessView.vue frontend/src/views/config/DiagnosticsView.vue frontend/src/router/index.js frontend/src/views/ConfigView.vue frontend/tests/config-center-domain-contract.test.mjs
git commit -m "feat: add devices config domain pages"
```

## Task 6: Migrate Business And Advanced Domain Pages

**Files:**
- Create: `frontend/src/views/config/MaterialsView.vue`
- Create: `frontend/src/views/config/PilesZonesView.vue`
- Create: `frontend/src/views/config/CalibrationView.vue`
- Create: `frontend/src/views/config/SystemOverviewView.vue`
- Create: `frontend/src/views/config/MaintenanceView.vue`
- Create: `frontend/src/views/config/ExpertParamsView.vue`
- Modify: `frontend/src/views/UserManagementView.vue`
- Modify: `frontend/src/router/index.js`
- Modify: `frontend/src/views/ConfigView.vue`

- [ ] **Step 1: Write failing assertions for business and advanced pages**

```js
test('advanced domain exposes system, maintenance, users, and expert params pages', () => {
  assert.match(routerSource, /advanced\/system/)
  assert.match(routerSource, /advanced\/maintenance/)
  assert.match(routerSource, /advanced\/users/)
  assert.match(routerSource, /advanced\/expert-params/)
})
```

- [ ] **Step 2: Run the route/domain tests**

Run: `rtk npm test -- config-center-route-contract.test.mjs config-center-domain-contract.test.mjs`  
Expected: FAIL on the new business/advanced route assertions

- [ ] **Step 3: Move `DataManageConfig` and calibration flow into dedicated views**

```vue
<ConfigPageShell eyebrow="业务基础" title="物料与密度基线" description="维护业务主数据与默认密度基线。">
  <DataManageConfig :material-types="materialTypes" @refresh="loadConfigViewData" />
</ConfigPageShell>
```

```vue
<ConfigPageShell eyebrow="业务基础" title="坐标校准" description="通过多步骤任务完成采集、标点、坐标输入和变换计算。">
  <!-- move the calibration step flow here -->
</ConfigPageShell>
```

- [ ] **Step 4: Move system overview, maintenance, users, and expert/runtime-advanced entry into advanced pages**

```vue
<UserManagementView />
```

```vue
<ConfigPageShell eyebrow="高级与维护" title="维护操作" description="执行备份、清理和重启动作前先核对能力状态。">
  <!-- move maintenance alerts and action buttons here -->
</ConfigPageShell>
```

- [ ] **Step 5: Run tests and build**

Run: `rtk npm test`  
Expected: PASS

Run: `rtk npm run build`  
Expected: PASS

- [ ] **Step 6: Commit**

```bash
git add frontend/src/views/config/MaterialsView.vue frontend/src/views/config/PilesZonesView.vue frontend/src/views/config/CalibrationView.vue frontend/src/views/config/SystemOverviewView.vue frontend/src/views/config/MaintenanceView.vue frontend/src/views/config/ExpertParamsView.vue frontend/src/views/UserManagementView.vue frontend/src/router/index.js frontend/src/views/ConfigView.vue
git commit -m "feat: add business and advanced config pages"
```

## Task 7: Remove Legacy Super-Container Responsibilities

**Files:**
- Modify: `frontend/src/views/ConfigView.vue`
- Modify: `frontend/src/router/index.js`
- Modify: `frontend/tests/auth-config-guard.test.mjs`

- [ ] **Step 1: Write the failing legacy-removal assertion**

```js
test('legacy ConfigView no longer contains the full multi-domain tab container', () => {
  assert.doesNotMatch(configViewSource, /label="运行参数"/)
  assert.doesNotMatch(configViewSource, /label="系统概览"/)
  assert.doesNotMatch(configViewSource, /label="用户管理"/)
})
```

- [ ] **Step 2: Run the focused test**

Run: `rtk npm test -- auth-config-guard.test.mjs`  
Expected: FAIL because `ConfigView.vue` still contains the old tabs

- [ ] **Step 3: Replace `ConfigView.vue` with a minimal redirect or legacy notice, then remove it from active routing**

```vue
<template>
  <RouterView />
</template>
```

- [ ] **Step 4: Run targeted tests**

Run: `rtk npm test -- auth-config-guard.test.mjs config-center-route-contract.test.mjs config-center-domain-contract.test.mjs`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add frontend/src/views/ConfigView.vue frontend/src/router/index.js frontend/tests/auth-config-guard.test.mjs
git commit -m "refactor: retire legacy config super view"
```

## Task 8: Final Verification And Docs Alignment

**Files:**
- Modify if needed: `frontend/docs/frontend-architecture.md`
- Verify: `docs/superpowers/specs/2026-04-15-config-center-redesign.md`

- [ ] **Step 1: Update architecture docs to reflect new config route map**

```md
- `views/config/` now hosts the multi-route config center
- `/config` no longer renders a single giant `ConfigView.vue`
```

- [ ] **Step 2: Run full verification**

Run: `rtk npm test`  
Expected: all Node contract tests pass

Run: `rtk npm run build`  
Expected: production build passes

- [ ] **Step 3: Manually verify these routes in dev mode**

```text
/config
/config/operations/runtime
/config/devices/plc
/config/business/materials
/config/advanced/maintenance
```

Expected:
- sidebar highlights config correctly
- domain nav changes with route
- save bars only appear on editable pages
- maintenance actions remain permission-gated

- [ ] **Step 4: Commit**

```bash
git add frontend/docs/frontend-architecture.md docs/superpowers/specs/2026-04-15-config-center-redesign.md
git commit -m "docs: align config center architecture notes"
```

## Self-Review

### Spec coverage

- Multi-route config center: Tasks 1-3
- Domain IA and page split: Tasks 3-6
- Page skeleton unification: Tasks 2-6
- Existing module relocation: Tasks 4-6
- Legacy `ConfigView` retirement: Task 7
- Verification and documentation: Task 8

### Placeholder scan

- No `TODO` / `TBD` placeholders remain.
- The only intentional staged limitation is `change-log`, which should start as a recent-save summary until backend audit support exists.

### Type consistency

- All route targets use the same `/config/<domain>/<page>` naming from the approved spec.
- Shared shell primitives are consistently named `ConfigDomainHero`, `ConfigPageShell`, and `ConfigQuickStatus`.
