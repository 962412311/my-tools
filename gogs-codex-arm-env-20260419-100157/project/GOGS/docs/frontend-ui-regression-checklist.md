# Frontend UI Regression Checklist

> Updated: 2026-04-07
> Automated verification completed: targeted `eslint`, full `npm run lint`, full `npm run build`
> Browser verification completed against real backend `192.168.1.211:8080` via local frontend `http://127.0.0.1:4173`
> Evidence artifacts: `/tmp/grab-ui-check/*.png`, `/tmp/grab-ui-check/*_report.json`

## Shared checks
- [x] 1920x1080 shell layout is balanced
- [x] 1366x768 shell layout keeps primary actions visible
- [x] Sidebar collapsed mode still communicates active route
- [x] Top status widgets show connection and runtime state clearly
- [x] Cards, tables, dialogs, and drawers share one visual language

## Page checks
- [x] Dashboard first screen shows summary + primary action path
- [x] Monitor first screen shows video/point cloud focus without right-panel clutter
- [x] Inventory and History expose summary + filters + table + detail pattern
- [x] Config shows grouped settings and sticky save affordance
- [x] Playback header, filter bar, and three-track linkage remain usable at 1366x768
- [x] Remote operation header, status strip, and right-rail controls remain usable at 1366x768
- [x] Login feedback and error states remain clear in industrial theme
