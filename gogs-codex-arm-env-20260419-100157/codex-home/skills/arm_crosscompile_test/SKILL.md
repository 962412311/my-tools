---
name: arm-crosscompile-test
description: "Use when working on this repository's ARM cross-compilation, deployment, or runtime verification flow, especially around `onebuild_GOGS_backend_self.sh`, `/userdata/GOGS`, `gogs-backend.service`, `nginx`, `rsync`, `git push`, or the compile and test hosts."
---

# ARM Cross-Compile And Test Orchestrator

Use this skill for the current repository's fixed build-and-test loop. Keep the workflow simple, direct, and tied to the project's known environment. Do not expand into general-purpose remote automation.

This skill is a repository-specific specialization of the global `stage-based-execution` method:

- keep fixed stage boundaries
- sink raw logs to files
- report only one-line `PASS/FAIL` summaries
- require machine-checkable verification before claiming success

Use the global method for the generic pattern and this skill for the repository's concrete hosts, paths, services, and field-proven fixes.

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

When you need a path, command, or service name, read the matching key from `runtime-targets.local.yml` instead of copying the value into this file.
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
- Maintain a Markdown record of confirmed environment facts, business rules, deployment constraints, troubleshooting conclusions, and verified workarounds while you work. Do not leave those facts only in chat history.
- After any code change, update the relevant Markdown documentation in the same work cycle before claiming the task is done. Code and docs must stay synchronized.
- Prefer idempotent install commands and verify the tool is available on `PATH` after installation.
- Keep compile-host dependencies, test-host runtime dependencies, and local-machine dependencies clearly separated.
- When adding a new dependency, check whether it belongs in the build environment, runtime environment, or both.

## Field-Proven Fixes To Preserve

These are fixed lessons from real deployment failures in this repository. Treat them as part of the standard workflow, not as optional troubleshooting ideas.

- Prefer `runtime-targets.local.yml` over the template whenever it exists. The compile host can change by site or LAN, and the local file is the approved place to pin the active address.
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

## Local Files

Keep environment-specific values in this directory under:

- `runtime-targets.template.yml`
- `runtime-targets.local.yml`

Treat `runtime-targets.local.yml` as the source of truth for the compile host, compile root, test host, runtime paths, service names, build command, and any environment notes.

## Working Rules

- Prefer the simplest command that works.
- Use `ssh jamin@<ip>`, `rsync`, `git push`, `systemctl status ...`, and direct file copy commands.
- Prefer the repository's fixed stage scripts when they exist. For this repository, use `scripts/arm/` as the primary entry instead of rebuilding ad hoc remote command chains in chat.
- Act autonomously. When a failure has a clear local fix, apply the fix and continue the workflow without pausing for approval. Only stop to ask the user when the decision is genuinely ambiguous, destructive, or changes the intended deployment target or architecture.
- Download git repositories, release archives, and other remote assets on the local machine first, then sync the prepared content to remote hosts unless the user explicitly wants remote-side cloning.
- Keep command lines short and explicit.
- If a command fails, fix the smallest local cause first.
- If a missing dependency is the local cause, install it in the correct environment and keep the setup flow up to date.
- If the build or deploy path is unclear, read the approved script instead of inventing a new one.
- Keep the workflow aligned with the live environment instead of adding compatibility layers.
- In repository work, prefer updating the repository-local field log and the affected docs immediately as facts are confirmed, instead of batching documentation until the end.
- Do not confuse the platform admin account with the camera credentials. For PTZ and ONVIF diagnosis, read `camera/username` and `camera/password` from the live config API or runtime config and use those exact values when probing the camera directly.
- Hikvision-style cameras on this stack can require `HTTP Digest + WS-UsernameToken` together for ONVIF. A plain unauthenticated probe or Digest-only curl is not enough evidence. When ONVIF availability is in doubt, verify `GetCapabilities` with a real SOAP request that includes WS-Security `UsernameToken` and the live camera credentials.
- For PTZ readiness validation on this project, do not rely on one snapshot. Verify in order: `GET /api/video/ptz/status`, `POST /api/video/ptz/move`, `POST /api/video/ptz/stop`, then a second `GET /api/video/ptz/status`, and check `journalctl` for `VideoManager: ONVIF connection state changed to connected`.
- For mediamtx embedded-player pages under `/media/hls/<path>/` or `/media/webrtc/<path>/`, validate with `GET`, not `HEAD`. A `HEAD` request can return `404` while the actual HTML player page is available with `GET`.
- When the frontend converts `hlsUrl` or `webrtcUrl` into a mediamtx embedded-player page, strip the proxy prefix before rebuilding the iframe URL. For example, `/media/webrtc/camera/whep` must map to `/media/webrtc/camera/`, not `/media/webrtc/media/webrtc/camera/`.
- After deploying hashed frontend assets, do not trust behavior from an already-open browser tab. Existing monitor pages can keep executing the old JS bundle and continue hitting retired APIs such as automatic `ptz/presets` loads until the user performs a full page refresh.
- If `npm run build` in `frontend/` fails with `Cannot find module @rollup/rollup-linux-x64-gnu`, treat it as a local optional-dependency problem. Run `npm install` in `frontend/`, then rebuild and only deploy the frontend after the build completes successfully.
- Keep ARM build/deploy/verify output low-noise. The standard is stage-based summaries, not long remote logs pasted into the conversation.
- Sink raw logs to files first. Only surface the stage name, verdict, critical artifact path, hashes, and the smallest failure excerpt needed to act.
- Treat commit/push as a separate publication step. The build/deploy pipeline must not auto-commit or auto-push unless the user explicitly asks for publication.

## Recommended Flow

### 1. Load local runtime targets

Read `runtime-targets.local.yml`.

If the local file is missing, fall back to the template and ask the user to fill the missing values.

### 2. Inspect the approved build script

The build script is expected to be an already-validated script that can be reused safely.

If the repository provides staged ARM wrapper scripts, prefer them:

```bash
bash scripts/arm/pipeline.sh
```

Or run individual stages directly:

```bash
bash scripts/arm/preflight.sh
bash scripts/arm/build_backend_remote.sh
bash scripts/arm/deploy_backend.sh
bash scripts/arm/deploy_frontend.sh
bash scripts/arm/verify_remote.sh
```

These scripts are the preferred low-noise execution path because they already implement stage boundaries, log sinking, and strong success criteria.

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

### 9. Commit and push when needed

If the task changed repository files and the user wants the changes published:

```bash
git status --short
git add -A
git commit -m "<concise message>"
git push
```

Keep the commit message short and descriptive. Do not create branches or use complex git flows unless the user asks for them.

## Stage-Based Output Standard

For repetitive ARM work, use the following phase model whenever possible:

1. `preflight`
2. `build_backend`
3. `deploy_backend`
4. `deploy_frontend`
5. `verify`

Each phase should report only:

- `PASS` or `FAIL`
- one concise result line
- the artifact path, hash, service state, or live endpoint needed to trust the outcome

Do not dump the full build, rsync, or journal output into the conversation unless the phase fails and the tail excerpt is required to diagnose the next action.

This phase model should stay aligned with the global `stage-based-execution` skill. Repository changes may specialize the stage names, but they should not regress back to chat-driven long-form execution.

## Logs And Verification

- Prefer writing detailed logs to `logs/arm/*.log`
- Prefer one-line phase summaries in the interactive output
- Verification should rely on machine-checkable evidence such as:
  - artifact existence and `sha256`
  - runtime binary hash equality
  - `systemctl is-active`
  - deployed frontend asset name
  - HLS playlist retrieval
  - PTZ readiness evidence from logs or APIs
  - radar callback evidence from logs
- If a phase cannot be strongly verified, do not report success yet

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
- If a remote step would require `git clone` or downloading release assets, prefer doing that work locally and syncing the result unless the user explicitly asks for remote-side downloads.
- If backend deployment succeeds but the service is down, check `gogs-backend.service` first, then logs, then the runtime directory.
- If nginx is up but the frontend is wrong, inspect the deployed `dist` content and the nginx document root.
- If nginx serves the frontend but `/media/hls/...` fails, inspect the active nginx site list for conflicting default servers before blaming mediamtx.
- If `/api/video/stream-info` still returns direct `:8888/:8889` URLs after a backend update, verify that the service was stopped before the binary copy and that the running `GrabSystem` path is actually `/userdata/GOGS/backend/GrabSystem`.
- After any backend deployment that touches video routing, log in with the deployed admin account and call `/api/video/stream-info` with a bearer token. Treat the returned `hlsUrl` and `webrtcUrl` as the final proof of whether the running backend contains the expected fix.
- If the test environment differs from the local config, update the local config instead of scattering ad-hoc exceptions through the skill.

## Practical Defaults

Use these defaults unless the local config says otherwise:

- Compile host: `jamin@100.89.114.123`
- Test host: `root@100.105.175.44`
- Onebuild command: `onebuild_GOGS_backend_self.sh`

Keep the skill tuned to this repository's fixed deployment path. Favor speed and directness over abstraction.
