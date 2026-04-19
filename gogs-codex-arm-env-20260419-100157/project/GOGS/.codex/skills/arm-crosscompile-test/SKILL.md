---
name: arm-crosscompile-test
description: "Use when working on this repository's ARM cross-compilation, deployment, or runtime verification flow, especially around `onebuild_GOGS_backend_self.sh`, `/userdata/GOGS`, `gogs-backend.service`, `nginx`, `rsync`, `git push`, or the compile and test hosts."
---

# ARM Cross-Compile And Test Orchestrator

Use this skill for the current repository's fixed build-and-test loop. Keep the workflow simple, direct, and tied to the project's known environment. Do not expand into general-purpose remote automation.

## Scope

This skill covers:

- Syncing the local source tree to the compile host
- Building the backend with `onebuild_GOGS_backend_self.sh`
- Building the frontend locally
- Deploying backend and frontend artifacts to the test host
- Downloading repository content and offline assets on the local machine before syncing them to remote hosts
- Installing required apt packages and directly-installable CLI tools on the target hosts
- Clearing stale build output and backend logs when needed
- Verifying the runtime with local HTTP and port checks
- Pushing changes only at phase boundaries

When you need a path, command, or service name, read the matching key from `.codex/skills/arm-crosscompile-test/references/runtime-targets.local.yml` instead of copying the value into this file.
If you do not remember the key name, search the `lookup_index` block in the local config first.

This skill does not do the following:

- Set up SSH keys
- Add jump hosts, proxies, tunnels, or extra authentication layers
- Try to support arbitrary projects or unknown deployment patterns
- Guess build parameters that are not present in the approved script or local config
- Replace the project's existing deployment scripts with a new generic framework

## Dependency And Environment Setup Rules

Treat environment setup as part of the task, not as an afterthought.

- If a remote host needs code, archives, model files, SDK bundles, or other repository-hosted content, download or prepare them on the local machine first, then sync them to the compile host or test host with `rsync` or direct copy.
- Do not turn the remote hosts into ad hoc download machines unless the user explicitly requires that path.
- If a build or verification step depends on apt packages, install them directly with `apt` on the relevant host instead of leaving the environment half-configured.
- If a required tool can be installed with the system package manager or a direct command-line installer, you may install it automatically when that unblocks the approved workflow.
- After installing dependencies, record or update the concrete setup steps in the repository-approved environment flow, local notes, or scripts so the environment can be reproduced.
- When a new runtime fact, constraint, or verified workaround is discovered during this workflow, immediately update the skill local config, the relevant repo docs, and any runtime notes that depend on it. Do not leave the new fact only in chat history.
- Maintain a repository-local Markdown field log at `.codex/skills/arm-crosscompile-test/references/field-notes.md`. During this workflow, every confirmed environment fact, business rule, deployment constraint, troubleshooting conclusion, and verified workaround must be written there promptly instead of living only in chat history.
- After any code change, update the relevant Markdown documentation in the same work cycle before claiming the task is done. Code and docs must stay in sync for runtime behavior, config keys, deployment steps, and verified field facts.
- Prefer idempotent install commands and verify the tool is available on `PATH` after installation.
- Keep compile-host dependencies, test-host runtime dependencies, and local-machine dependencies clearly separated.
- When adding a new dependency, check whether it belongs in the build environment, runtime environment, or both.
- The ARM test host already has a complete Qt runtime environment under `/userdata/GOGS`; do not assume it needs a fresh Qt runtime install just because a launch step fails.
- For runtime verification on the test host, prefer the deployment directory and its existing one-click backend startup script over inventing a new ad hoc launch path.
- The test host backend launch script is `/userdata/GOGS/backend/start.sh`; it sets `LD_LIBRARY_PATH=/opt/qt6.2.4-aarch64/lib` and then `exec`s `./GrabSystem`. Use it when you need a manual backend start on the deployed runtime tree.
- Older repository docs may still mention `runtime/`; for the deployed ARM test host, treat `/userdata/GOGS` as the real runtime root.

## Field-Proven Fixes To Preserve

These are fixed lessons from real deployment failures in this repository. Treat them as part of the standard workflow, not as optional troubleshooting ideas.

- Prefer `.codex/skills/arm-crosscompile-test/references/runtime-targets.local.yml` over the template whenever it exists. The compile host can change by site or LAN, and the local file is the approved place to pin the active address.
- Treat the deployed RK3588 device as a performance-constrained production target. For all point-cloud and video work, optimize for end-to-end throughput, low CPU overhead, low memory bandwidth pressure, and low transfer cost first; do not default to "functionally correct now, optimize later" on those paths.
- Before every backend build on the compile host, delete the existing backend executable output first. In this repository, remove the compile-host `GrabSystem` binary before invoking the build so a stale old file cannot be mistaken for a newly built artifact.
- When replacing `/userdata/GOGS/backend/GrabSystem` on the ARM test host, stop `gogs-backend.service` first. Do not rely on overwriting the binary while the service is running.
- The reliable backend replacement sequence on the test host is:
  1. `systemctl stop gogs-backend.service`
  2. upload the new binary to `/tmp/GrabSystem.arm.new`
  3. `cp /tmp/GrabSystem.arm.new /userdata/GOGS/backend/GrabSystem`
  4. `chmod +x /userdata/GOGS/backend/GrabSystem`
  5. `systemctl start gogs-backend.service`
  6. `systemctl is-active gogs-backend.service`
- Before replacing the backend binary, back up the current binary with a timestamped copy and clear `/userdata/GOGS/backend/logs/*` so new restart logs are clean.
- If backend cross-compilation suddenly fails with `QTimer does not name a type` in `VideoManager.h`, fix the header dependency first by ensuring `#include <QTimer>` is present before retrying the build. Do not treat that failure as an environment problem.
- For live video on the test host, nginx must proxy:
  - `/media/hls/` -> `http://127.0.0.1:8888/`
  - `/media/webrtc/` -> `http://127.0.0.1:8889/`
- If nginx warns about a conflicting default server, remove the stale site before trusting frontend or media verification results.
- For mediamtx HLS checks on this stack, prefer `GET` over `HEAD` for `index.m3u8`. `HEAD` can return `404` while `GET` returns a valid playlist.
- The current field camera stream is H.265/HEVC. Browser HLS playback can still fail even when RTSP and mediamtx are healthy. If video is still blank after media proxy verification, check whether the deployed frontend includes the mediamtx embedded-player fallback for incompatible codecs.

## SDK-First Rules For Radar Work

When the task touches radar connectivity, point cloud reception, DIF/PCF parsing, runtime verification, field diagnosis, or "frontend cannot see radar data", do not rely on intuition, stale memory, or generic network assumptions.

Before changing code or assigning blame, you must inspect the SDK itself and use it as the primary evidence source.

Always check as many of the following as are relevant:

- SDK README files
- SDK `doc/` documents
- SDK example programs such as `Demo_UseSDK.cpp`
- Any SDK-side GUI or helper scripts
- The actual SDK source used by the project, especially `LidarDevice.cpp`, `LidarDevice.h`, and related parsing code
- Any additional SDK branches or bundled demo objects when the current snapshot is incomplete

For this repository, that usually means checking paths under:

- `backend/SDK/LidarView/armlinux2026123/sdk/README.md`
- `backend/SDK/LidarView/armlinux2026123/sdk/doc/`
- `backend/SDK/LidarView/armlinux2026123/sdk/demo/`
- `backend/SDK/LidarView/armlinux2026123/sdk/lidar/`
- `backend/SDK/LidarView/armlinux2026123/src/tensorpro_interfaces/`

Treat the SDK as authoritative for:

- expected lidar type
- required host IP / lidar IP / data port / DIF port / IMU port
- packet length expectations
- whether DIF is required before point cloud callbacks
- whether a model supports work-mode switching or network queries
- whether a control path is model-specific, such as TW360-only features

Do not claim "the radar is connected", "the frontend is broken", "the SDK is wrong", or "the network is fine" unless the claim is backed by SDK behavior, SDK logs, or direct packet evidence.

If the current SDK snapshot appears incomplete, you must inspect available SDK git history or related bundled demo artifacts before concluding that a capability does not exist.

## Local Files

Keep environment-specific values in this repository under:

- `.codex/skills/arm-crosscompile-test/references/runtime-targets.template.yml`
- `.codex/skills/arm-crosscompile-test/references/runtime-targets.local.yml`
- `.codex/skills/arm-crosscompile-test/references/field-notes.md`

Treat the `.local.yml` file as the source of truth for the compile host, compile root, test host, runtime paths, service names, build command, and any environment notes.
Treat `field-notes.md` as the default repository log for confirmed field facts, business constraints, deployment lessons, and verification results gathered during this workflow.

Use the template file as a starting point when the local file is missing.

## Working Rules

- Prefer the simplest command that works.
- Use `ssh jamin@<ip>`, `rsync`, `git push`, `systemctl status ...`, and direct file copy commands.
- Act autonomously. When a failure has a clear local fix, apply the fix and continue the workflow without pausing for approval. Only stop to ask the user when the decision is genuinely ambiguous, destructive, or changes the intended deployment target or architecture.
- The local machine can reach the ARM test host directly; prefer running local `curl`, `ssh`, and other network checks against the test host before inventing alternate paths or blaming connectivity.
- Download git repositories, release archives, and other remote assets on the local machine first, then sync the prepared content to remote hosts unless the user explicitly wants remote-side cloning.
- Keep command lines short and explicit.
- If a command fails, fix the smallest local cause first.
- If a missing dependency is the local cause, install it in the correct environment and keep the setup flow up to date.
- If the build or deploy path is unclear, read the approved script instead of inventing a new one.
- Keep the workflow aligned with the live environment instead of adding compatibility layers.
- Update `.codex/skills/arm-crosscompile-test/references/field-notes.md` as you work, not at the very end. If a conclusion changed, revise or supersede the old note instead of leaving contradictory history unresolved.
- Backend compilation must use the cross-compile host. Do not treat the test host as a fallback build machine for backend binaries.
- If the compile host is temporarily unreachable, pause backend rebuild work and continue with runtime verification or source inspection only; do not try to invent a native test-host backend build path.
- The test host may still be used for runtime verification, log checks, packet capture, and deployment validation, but not for backend compilation.
- Do not fake Qt host tools with Qt5 binaries. If a backend build actually needs to run on the compile host, it must use the proper Qt6-compatible host tools (`moc`, `rcc`, `uic`) and a working `qt-cmake` on that host.
- For backend auth/WebSocket issues, treat `system/allowed_origins` as runtime config that may be rewritten by the backend into legacy bracket form; the parser must accept both valid JSON arrays and legacy bracket/list syntax.
- For backend auth/WebSocket issues, treat `security/jwt_secret` as an auto-generated runtime secret when missing or still a placeholder. Do not require manual secret entry if the backend already persists the generated value back to the runtime config.
- For the deployed ARM test host, `/ws` is proxied by nginx to backend port `12345`. If the browser origin is not accepted, prefer rewriting the websocket proxy `Origin` header in nginx to one of the backend defaults (`http://localhost:5173`, `http://localhost:3000`, `http://localhost:8080`, `http://127.0.0.1:5173`, `http://127.0.0.1:3000`, `http://127.0.0.1:8080`) before touching backend config files.
- `system/allowed_origins` is not exposed by the frontend config API on the current backend build. Direct file edits may be rewritten on startup, so do not assume a manual `config.ini` change will persist or take effect.
- The default/bootstrapped admin account is `admin` / `Admin@123`. Keep the deployed test-host admin password aligned with that initializer so the database, init path, and documentation stay consistent.
- For browser auto-login flows, the frontend must keep `userInfo.exp` in sync when refresh tokens succeed; otherwise `isLoggedIn` can go false even though `token` was refreshed, and websocket initialization / route guards will drift apart.
- Add explicit console logs around auth bootstrap, token refresh, websocket connect/reconnect/close, and HTTP polling fallback when diagnosing "refresh-to-stay-logged-in" issues. Prefer logs that show whether the session was restored from localStorage and whether websocket reconnect was triggered by a token change.
- If the browser is already auto-logged-in but websocket still fails to connect, try a silent auth recovery path before blaming the frontend shell: reuse `refreshToken` once on websocket close, refresh the access token, and let the token watcher trigger reconnect. Log the recovery attempt and whether it succeeded.
- When verifying browser auto-login, distinguish between "login session restored" and "websocket session restored". A restored `token` without a successful websocket open is still a broken runtime state.
- If websocket drops without a clean close event, add or keep a lightweight health check or watchdog that forces reconnect when the socket is stale; do not rely only on `onclose`.
- For the final browser-side display check after deployment, stop at a deployment-ready state and hand the visual/runtime confirmation to the user. Do not claim the final display pass unless the user explicitly confirms it.
- Backend auth on this project is JWT-like but not fully stateless: older code paths tied token validity to an in-memory cache. If persisted browser tokens stop working after a backend restart or cache loss, inspect `AuthManager::validateToken()` and `refreshToken()` first and prefer signature+expiry validation over cache-only rejection.
- Frontend production builds strip `console.*` through Vite/esbuild settings. Do not rely on browser console output from the deployed artifact for diagnosis unless you intentionally changed the build pipeline; use backend logs, nginx logs, or temporary debug flags instead.
- For point cloud display tuning, keep the visible size control unified across monitor and playback views. Use the shared frontend store `frontend/src/stores/pointCloudDisplay.js`, the round-sprite helper in `frontend/src/utils/pointCloudMaterial.js`, and a single slider-style control with a circular handle that shows discrete levels `1-20` while mapping to the actual size range `0.005-0.05`; do not keep per-page hardcoded sizes or per-page input boxes.
- For point cloud processing diagnostics, treat `droppedFrames` as a cumulative queue-eviction counter, not as a live health score. Dashboard-style health indicators should prefer a rolling recent-window drop rate plus `queueCapacity`/`queuedFrames` so the UI reflects current pressure instead of permanent historical accumulation. If the queue is briefly over pressure, enlarge the queue modestly first before blaming the display layer.
- Dashboard-style health indicators should use `recentDropRate` and `recentDroppedFrames` as the live point-cloud health signal. Treat `recentDropRate` as a true recent-window queue-eviction ratio, not a raw "drops per processed frame" count. Do not fall back to `droppedFrames / frameIndex` for the live score once recent-window fields are available.
- Point-cloud processing now uses a frame-analysis worker pool plus an ordered fusion/commit stage. Keep the frame-local analysis path parallelizable, but preserve monotonically increasing sequence ids for the commit stage; do not collapse the code back into one single serial loop unless profiling proves the worker split is wrong.
- When refactoring the point-cloud worker pool, never hold the shared processing mutex across `snapshotFrameAnalysisInput()` or task startup. That path can self-deadlock the worker thread, starve the main Qt event loop, and make `/health` or `/api/auth/login` appear to hang even though the backend process is still alive.
- After fixing the worker-pool deadlock, keep the HTTP server on `keep-alive` unless there is a specific debugging reason to force close connections; forcing a close adds churn to auth/config traffic and is not a substitute for fixing the point-cloud thread model.
- For monitor page PTZ controls, load PTZ status first and only fetch presets when the status says the PTZ stack is ready; if presets are not ready, avoid auto-firing the slow ONVIF preset query on page mount.
- Do not confuse the platform admin account with the camera credentials. For PTZ and ONVIF diagnosis, read `camera/username` and `camera/password` from the live config API or runtime config and use those exact values when probing the camera directly.
- Hikvision-style cameras on this stack can require `HTTP Digest + WS-UsernameToken` together for ONVIF. A plain unauthenticated probe or Digest-only curl is not enough evidence. When ONVIF availability is in doubt, verify `GetCapabilities` with a real SOAP request that includes WS-Security `UsernameToken` and the live camera credentials.
- For this project's PTZ readiness, a successful `/api/video/ptz/move` or `/api/video/ptz/stop` followed by `VideoManager: ONVIF connection state changed to connected` in `journalctl` is valid evidence that the backend has established a working PTZ path, even if an earlier first-load status snapshot showed `ready=false`.
- When deploying a PTZ status fix, verify the sequence explicitly: first `GET /api/video/ptz/status`, then `POST /api/video/ptz/move`, then `POST /api/video/ptz/stop`, then a second `GET /api/video/ptz/status`. Do not claim the status path is fixed from only one of those checks.
- For mediamtx embedded-player pages under `/media/hls/<path>/` or `/media/webrtc/<path>/`, validate with `GET`, not `HEAD`. A `HEAD` request can return `404` while the actual HTML player page is available with `GET`.
- When the frontend converts `hlsUrl` or `webrtcUrl` into a mediamtx embedded-player page, strip the proxy prefix before rebuilding the iframe URL. For example, `/media/webrtc/camera/whep` must map to `/media/webrtc/camera/`, not `/media/webrtc/media/webrtc/camera/`.
- After deploying hashed frontend assets, do not trust behavior from an already-open browser tab. Existing monitor pages can keep executing the old JS bundle and continue hitting retired APIs such as automatic `ptz/presets` loads until the user performs a full page refresh.
- If `npm run build` in `frontend/` fails with `Cannot find module @rollup/rollup-linux-x64-gnu`, treat it as a local optional-dependency problem. Run `npm install` in `frontend/`, then rebuild and only deploy the frontend after the build completes successfully.
- For radar issues, prefer direct evidence in this order:
  1. SDK docs and example programs
  2. SDK runtime logs
  3. Direct packet capture on the test host
  4. Minimal isolated SDK demo runs on the test host
  5. Project integration code
- Do not skip straight to frontend or application-layer hypotheses when SDK demo evidence is still missing.

## Recommended Flow

## Preferred Automation Entry

For the current repository, prefer the stage-based wrapper scripts under `scripts/arm/` over ad hoc terminal orchestration whenever the task is a standard "build, deploy, verify" cycle.

Use:

```bash
bash scripts/arm/pipeline.sh
```

Stage scripts:

- `bash scripts/arm/preflight.sh`
- `bash scripts/arm/build_backend_remote.sh`
- `bash scripts/arm/deploy_backend.sh`
- `bash scripts/arm/deploy_frontend.sh`
- `bash scripts/arm/verify_remote.sh`

Behavior requirements:

- Each stage must print a single summary line in the form `PASS/FAIL + short result`.
- Full command output must go to `logs/arm/*.log`.
- A failure summary must include the stage name, log path, and a short tail excerpt only.
- Success must be judged by strong checks, not by eyeballing raw output.
- The pipeline scripts must not auto-commit or auto-push source changes. Treat git publication as a separate explicit boundary.
- Do not keep large numbers of hanging `ssh` / `rsync` sessions open just to poll progress.
- Do not flood the user with compiler warnings or long remote logs when a one-line stage summary is sufficient.

### 1. Load local runtime targets

Read `.codex/skills/arm-crosscompile-test/references/runtime-targets.local.yml`.

If the local file is missing, fall back to the template and ask the user to fill the missing values.

### 2. Inspect the approved build script

The build script is expected to be an already-validated script that can be reused safely.

Primary backend build entrypoint:

```bash
onebuild_GOGS_backend_self.sh
```

Only fall back to the repository's native scripts when the onebuild command is unavailable or the local config explicitly says to use the repository flow.

When reading it, extract only the values that are actually used:

- source directory
- build directory
- install directory
- output artifact name
- preset or target name
- any copy or sync destination
- any environment variables the script requires, especially `Qt6_DIR`, `PCL_DIR`, `Eigen3_DIR`, and `SYSROOT`

Prefer explicit assignments and fixed command lines in the script. If the script uses simple shell variables, read those variables directly. If the script is more complex, stop after extracting the concrete paths that are already obvious from the file.

The onebuild script clears its own build directory before configuring, so no separate cleanup step is needed.

### 3. Sync code to the compile server

Use the compile host from local config.

If extra repositories, archives, SDK packages, or generated assets are needed for the build, fetch them locally first and sync the resulting directory or package to the compile host. Prefer this over running `git clone` or arbitrary downloads on the remote machine.

Run:

```bash
rsync -a --delete --exclude '.git' ./ jamin@100.89.114.123:<compile_root>/
ssh jamin@100.89.114.123
cd <compile_root>
rm -f <backend_output_path>/GrabSystem
onebuild_GOGS_backend_self.sh
```

Do not add extra SSH options unless the local config requires them. Do not push after each sync; only push when a phase is ready to publish.

### 4. Build backend on the compile server

Run the backend build with the onebuild command first:

```bash
rm -f <backend_output_path>/GrabSystem
onebuild_GOGS_backend_self.sh
```

If the onebuild command is unavailable, fall back to the repository's existing native build flow:

```bash
./scripts/build-native-backend.sh backend-linux-release
```

If the compile step fails because tools or libraries are missing, install the required apt packages or directly-installable CLI tools on the compile host, then re-run the build. Keep the install sequence explicit so the environment can be rebuilt later.

### 5. Build frontend locally

Build the frontend on the current machine before deploying it to the test server.

Prefer the repository's existing frontend build entrypoint:

```bash
./scripts/frontend-build.sh
```

Only fall back to another frontend build command if the approved script or local config says so.

### 6. Deploy backend to the test server

Deploy backend artifacts to the ARM Linux test host using the runtime root from local config.

Default runtime layout:

- backend executable: `/userdata/GOGS/backend/GrabSystem`
- backend working directory: `/userdata/GOGS/backend`
- backend config: `/userdata/GOGS/backend/config/config.ini`
- backend logs: `/userdata/GOGS/backend/logs/grab_system.log`
- frontend static files: `/userdata/GOGS/frontend/dist`
- backend fallback static files: `/userdata/GOGS/backend/web`

Use `rsync -a --delete` for deployment so only changed files move across the link. Keep the deployment path aligned with the repository's runtime layout.

### 7. Deploy frontend to the test server

After local frontend build, sync `frontend/dist` from the local machine to the test server.

Mirror the built files to both of these paths when the runtime expects them:

- `/userdata/GOGS/frontend/dist`
- `/userdata/GOGS/backend/web`

This matches the repository's current deployment scripts and avoids extra special cases.

If the frontend serves live video through mediamtx, also make sure the active nginx site includes `/media/hls/` and `/media/webrtc/` proxies before concluding that the RTSP or mediamtx side is broken.

Before restarting the backend, remove stale files from `/userdata/GOGS/backend/logs` on the test host so new test runs start with clean logs.

### 8. Verify the test server

Use local HTTP and port checks against the test host whenever possible. Use SSH only for service control or log cleanup when the local checks show a problem.

Confirm the runtime with:

- `curl http://100.105.175.44/`
- `curl http://100.105.175.44:8080/api/system/info`
- `curl http://100.105.175.44/media/hls/camera/index.m3u8`
- `curl http://100.105.175.44/media/hls/camera/`
- `ss -ltnp | grep -E ':8080|:12345'` when you need a port check
- `systemctl status gogs-backend.service --no-pager` when SSH access is needed
- `systemctl status nginx --no-pager` when SSH access is needed
- `journalctl -u gogs-backend.service -n 100 --no-pager` if the backend is unhealthy
- `curl http://127.0.0.1:9997/v3/paths/list` on the test host when mediamtx path readiness is in doubt
- `curl http://127.0.0.1:9997/v3/hlsmuxers/list` on the test host when HLS muxer creation is in doubt

Treat `gogs-backend.service` as the backend service. Treat `nginx` as the frontend service. If the backend was redeployed, restart `gogs-backend.service` after clearing `/userdata/GOGS/backend/logs`.

If verification needs a missing runtime utility, install it on the test host with the simplest reproducible method, then continue the check.

### 8A. Radar-Specific Verification

When validating radar behavior on the test host, use direct and minimal checks instead of inference.

Recommended order:

1. Confirm the project's configured lidar model, IP, and ports from runtime config and integration code.
2. Read the matching SDK docs and example code for that exact model.
3. Confirm whether the model requires DIF before point cloud callbacks.
4. Use `tcpdump`, `ss -lun`, and service stop/start to determine whether the host actually receives radar UDP.
5. When possible, compile and run the SDK's own demo on the test host with field config values to separate SDK behavior from project integration behavior.

If the SDK demo on the test host reproduces the same timeout or zero-packet behavior as the project, treat that as strong evidence that the problem is upstream of project integration.

If packet capture shows zero UDP packets reaching the configured host IP and ports, do not blame frontend rendering or higher-level point-cloud processing.

### 9. Commit and push when needed

If the task changed repository files and the user wants the changes published:

```bash
git status --short
git add -A
git commit -m "<concise message>"
git push
```

Keep the commit message short and descriptive. Do not create branches or use complex git flows unless the user asks for them.

## Script Parsing Rules

When reading an approved build or deploy script:

- Trust explicit path variables over inference
- Read `SOURCE_DIR`, `BUILD_DIR`, `INSTALL_DIR`, `OUTPUT_DIR`, `TARGET`, `PRESET`, and similar names first
- Treat `cd`, `cmake`, `make`, `ninja`, `cp`, `rsync`, and `scp` lines as path sources
- Ignore generic shell boilerplate
- Do not invent compatibility fallbacks for unknown shell syntax

If the script does not clearly expose the needed values, fall back to the repository's existing scripts and the local runtime config rather than guessing.

## Error Handling

- If SSH fails, check host key setup and key auth first.
- If `git pull` fails on the compile server, inspect the remote branch state before changing anything.
- If a remote step would require `git clone` or downloading release assets, prefer doing that work locally and syncing the result unless the user explicitly asks for remote-side downloads.
- If backend deployment succeeds but the service is down, check `grab-system.service` first, then logs, then the runtime directory.
- If nginx is up but the frontend is wrong, inspect the deployed `dist` content and the nginx document root.
- If nginx serves the frontend but `/media/hls/...` fails, inspect the active nginx site list for conflicting default servers before blaming mediamtx.
- If `/api/video/stream-info` still returns direct `:8888/:8889` URLs after a backend update, verify that the service was stopped before the binary copy and that the running `GrabSystem` path is actually `/userdata/GOGS/backend/GrabSystem`.
- After any backend deployment that touches video routing, log in with the deployed admin account and call `/api/video/stream-info` with a bearer token. Treat the returned `hlsUrl` and `webrtcUrl` as the final proof of whether the running backend contains the expected fix.
- If the test environment differs from the local config, update the local config instead of scattering ad-hoc exceptions through the skill.
- If the browser still shows `WebSocket未连接` after a fresh login, verify both the backend binary version and the runtime `allowed_origins` value before blaming the frontend store or token flow.
- If radar behavior is unclear, stop guessing and go back to SDK docs, SDK demo code, and packet capture.
- If the current SDK working tree is missing files referenced by docs or compiled demos, inspect SDK git branches before declaring that the feature is unavailable.

## Practical Defaults

Use these defaults unless the local config says otherwise:

- Compile host: `jamin@100.89.114.123`
- Test host: `root@100.105.175.44`
- Onebuild command: `onebuild_GOGS_backend_self.sh`

Keep the skill tuned to this repository's fixed deployment path. Favor speed and directness over abstraction.
