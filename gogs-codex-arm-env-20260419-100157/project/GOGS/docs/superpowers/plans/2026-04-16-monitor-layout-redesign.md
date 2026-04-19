# Monitor Layout Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild the monitor front-end so video and point cloud become equal primary stages, detailed diagnostics move into collapsible lower workbench panels, and the page remains usable on both wide desktops and laptop screens.

**Architecture:** Keep existing data flow and backend contracts intact. Restructure `MonitorView` into a three-part workbench, introduce focused monitor layout helpers where needed, and reduce `CameraPanel` to a first-screen quick-control role while preserving current PTZ/video behavior.

**Tech Stack:** Vue 3 SFCs, Element Plus, existing layout primitives (`PageHeader`, `SectionCard`), Node contract tests, Vite build.

---

## File Map

- Modify: `frontend/src/views/MonitorView.vue`
  - Recompose the page shell, dual-stage workbench, light rail, and lower collapsible panels.
- Modify: `frontend/src/components/monitor/CameraPanel.vue`
  - Align the split-mode video stage with the quick-control-first design.
- Modify: `frontend/src/components/monitor/DiagnosticsPanel.vue`
  - Adapt diagnostics for lower workbench usage instead of first-screen dominance.
- Create: `frontend/src/components/monitor/MonitorWorkbenchPanels.vue`
  - Own the collapsible lower workbench sections.
- Create: `frontend/src/components/monitor/MonitorLightRail.vue`
  - Own the right-side / laptop-summary cards for runtime, highest-point actions, and PTZ quick controls.
- Modify: `frontend/tests/layout-polish-contract.test.mjs`
- Modify: `frontend/tests/monitor-split-layout-contract.test.mjs`
- Modify: `frontend/tests/video-stream-resilience.test.mjs`
- Create: `frontend/tests/monitor-layout-workbench-contract.test.mjs`

## Task 1: Lock The New Layout Contract In Tests

**Files:**
- Modify: `frontend/tests/layout-polish-contract.test.mjs`
- Modify: `frontend/tests/monitor-split-layout-contract.test.mjs`
- Modify: `frontend/tests/video-stream-resilience.test.mjs`
- Create: `frontend/tests/monitor-layout-workbench-contract.test.mjs`

- [ ] **Step 1: Write failing contract tests for the redesigned monitor hierarchy**

Add assertions for:
- dual-stage workbench vocabulary
- lower collapsible workbench section labels
- light rail card labels
- reduced first-screen header actions
- laptop breakpoint behavior

- [ ] **Step 2: Run the targeted monitor contract tests and confirm they fail**

Run:

```bash
rtk npm test -- monitor-split-layout-contract.test.mjs layout-polish-contract.test.mjs video-stream-resilience.test.mjs monitor-layout-workbench-contract.test.mjs
```

Expected:
- at least one failure mentioning missing lower workbench / light rail / updated split layout expectations

- [ ] **Step 3: Keep the failing expectations narrow**

Ensure tests still preserve existing behavior contracts for:
- `loadVideoStreamInfo`
- PTZ action wiring
- point cloud viewport rebuild

- [ ] **Step 4: Re-run the same targeted tests**

Run:

```bash
rtk npm test -- monitor-split-layout-contract.test.mjs layout-polish-contract.test.mjs video-stream-resilience.test.mjs monitor-layout-workbench-contract.test.mjs
```

Expected:
- failures are only about the new layout contract

## Task 2: Build The Lower Workbench And Light Rail Components

**Files:**
- Create: `frontend/src/components/monitor/MonitorWorkbenchPanels.vue`
- Create: `frontend/src/components/monitor/MonitorLightRail.vue`
- Modify: `frontend/src/components/monitor/DiagnosticsPanel.vue`

- [ ] **Step 1: Implement a dedicated lower workbench component**

The component should render four sections:
- `链路状态`
- `设备诊断`
- `日志与搜索`
- `扩展工具`

It should support:
- one default-expanded section (`链路状态`)
- simple `el-collapse` or equivalent structure
- slots/props for diagnostics, logs, search results, and extension tools

- [ ] **Step 2: Implement a dedicated light rail component**

The component should own only:
- runtime overview
- highest-point actions
- PTZ quick controls

It must not render:
- full video diagnostics
- full logs
- search results

- [ ] **Step 3: Adapt DiagnosticsPanel for lower-workbench embedding**

Keep existing actions and props intact, but reduce assumptions about always living in the first-screen sidebar.

- [ ] **Step 4: Run focused contract tests**

Run:

```bash
rtk npm test -- monitor-layout-workbench-contract.test.mjs
```

Expected:
- component presence and section labels pass

## Task 3: Recompose MonitorView Around The New Workbench

**Files:**
- Modify: `frontend/src/views/MonitorView.vue`

- [ ] **Step 1: Replace the heavy right sidebar model with the new workbench structure**

Implement this screen hierarchy:
- `PageHeader`
- `monitor-toolbar`
- `monitor-stage-workbench`
  - dual-stage area
  - light rail
- lower workbench panels

- [ ] **Step 2: Keep video and point cloud as equal primary stages in split mode**

Split mode should continue to show:
- one video stage
- one point cloud stage

but move detailed diagnostics out of first screen.

- [ ] **Step 3: Reduce header actions to high-frequency monitor actions**

Keep:
- record
- screenshot
- copy video summary

Move low-frequency tools to toolbar or lower workbench.

- [ ] **Step 4: Preserve existing data/behavior hooks**

Keep these live in `MonitorView`:
- `loadVideoStreamInfo`
- `loadVideoRecordingStatus`
- `loadVideoSelfCheck`
- point cloud rendering lifecycle
- PTZ request functions

Do not change backend service calls.

- [ ] **Step 5: Run targeted monitor tests**

Run:

```bash
rtk npm test -- monitor-split-layout-contract.test.mjs layout-polish-contract.test.mjs video-stream-resilience.test.mjs monitor-layout-workbench-contract.test.mjs monitor-display-contract.test.mjs point-cloud-display.test.mjs
```

Expected:
- updated layout contracts pass
- no regressions in stream / point-cloud contracts

## Task 4: Refactor CameraPanel Into A Quick-Control-First Stage

**Files:**
- Modify: `frontend/src/components/monitor/CameraPanel.vue`
- Modify: `frontend/src/views/MonitorView.vue`

- [ ] **Step 1: Simplify split-mode camera panel visual hierarchy**

Make split-mode emphasize:
- top overlay info
- main video stage
- compact PTZ quick controls

Do not let detailed PTZ diagnostics dominate the stage.

- [ ] **Step 2: Preserve all existing emits and control behaviors**

Do not break:
- `ptz-move`
- `ptz-stop`
- `ptz-reset`
- `zoom-change`
- `preset-go`
- `preset-save`
- `toggle-fullscreen`
- `snapshot`
- `record`

- [ ] **Step 3: Keep preset loading behavior lazy**

Do not reintroduce eager PTZ preset loading on mount or polling.

- [ ] **Step 4: Run PTZ and monitor resilience tests**

Run:

```bash
rtk npm test -- ptz-control-contract.test.mjs video-stream-resilience.test.mjs auth-config-guard.test.mjs monitor-split-layout-contract.test.mjs
```

Expected:
- PTZ contracts remain green
- lazy preset loading remains intact

## Task 5: Responsive Polish And Final Verification

**Files:**
- Modify: `frontend/src/views/MonitorView.vue`
- Modify: `frontend/src/components/monitor/MonitorWorkbenchPanels.vue`
- Modify: `frontend/src/components/monitor/MonitorLightRail.vue`
- Modify: `frontend/src/components/monitor/CameraPanel.vue`

- [ ] **Step 1: Add responsive rules for three states**

Support:
- wide desktop: video / point cloud / light rail
- laptop: stacked dual-stage + horizontal summary cards
- narrow: single primary stage + collapsed support sections

- [ ] **Step 2: Ensure point cloud canvas still resizes and rebuilds correctly**

Do not regress `ensurePointCloudViewport`, `handleResize`, or layout-mode watches.

- [ ] **Step 3: Run the monitor-focused test suite**

Run:

```bash
rtk npm test -- monitor-layout-workbench-contract.test.mjs monitor-split-layout-contract.test.mjs layout-polish-contract.test.mjs video-stream-resilience.test.mjs monitor-display-contract.test.mjs ptz-control-contract.test.mjs point-cloud-display.test.mjs point-cloud-scene-contract.test.mjs point-cloud-picking-contract.test.mjs
```

Expected:
- all selected monitor/layout contracts pass

- [ ] **Step 4: Run production build**

Run:

```bash
rtk npm run build
```

Expected:
- Vite build exits with code 0

- [ ] **Step 5: Review the final diff for scope discipline**

Confirm the diff only includes:
- monitor front-end layout work
- monitor-related tests
- new monitor layout helper components

No backend or unrelated config-center changes should be introduced by this task.
