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

## Local Files

Keep environment-specific values in this directory under:

- `runtime-targets.template.yml`
- `runtime-targets.local.yml`

Treat `runtime-targets.local.yml` as the source of truth for the compile host, compile root, test host, runtime paths, service names, build command, and any environment notes.

## Working Rules

- Prefer the simplest command that works.
- Use `ssh jamin@<ip>`, `rsync`, `git push`, `systemctl status ...`, and direct file copy commands.
- Keep command lines short and explicit.
- If a command fails, fix the smallest local cause first.
- If the build or deploy path is unclear, read the approved script instead of inventing a new one.
- Keep the workflow aligned with the live environment instead of adding compatibility layers.

## Recommended Flow

### 1. Load local runtime targets

Read `runtime-targets.local.yml`.

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

Run:

```bash
rsync -a --delete --exclude '.git' ./ jamin@100.89.114.123:<compile_root>/
ssh jamin@100.89.114.123
cd <compile_root>
onebuild_GOGS_backend_self.sh
```

Do not add extra SSH options unless the local config requires them. Do not push after each sync; only push when a phase is ready to publish.

### 4. Build backend on the compile server

Run the backend build with the onebuild command first:

```bash
onebuild_GOGS_backend_self.sh
```

If the onebuild command is unavailable, fall back to the repository's existing native build flow:

```bash
./scripts/build-native-backend.sh backend-linux-release
```

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

Before restarting the backend, remove stale files from `/userdata/GOGS/backend/logs` on the test host so new test runs start with clean logs.

### 8. Verify the test server

Use local HTTP and port checks against the test host whenever possible. Use SSH only for service control or log cleanup when the local checks show a problem.

Confirm the runtime with:

- `curl http://100.105.175.44/`
- `curl http://100.105.175.44:8080/api/system/info`
- `ss -ltnp | grep -E ':8080|:12345'` when you need a port check
- `systemctl status gogs-backend.service --no-pager` when SSH access is needed
- `systemctl status nginx --no-pager` when SSH access is needed
- `journalctl -u gogs-backend.service -n 100 --no-pager` if the backend is unhealthy

Treat `gogs-backend.service` as the backend service. Treat `nginx` as the frontend service. If the backend was redeployed, restart `gogs-backend.service` after clearing `/userdata/GOGS/backend/logs`.

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
- If backend deployment succeeds but the service is down, check `gogs-backend.service` first, then logs, then the runtime directory.
- If nginx is up but the frontend is wrong, inspect the deployed `dist` content and the nginx document root.
- If the test environment differs from the local config, update the local config instead of scattering ad-hoc exceptions through the skill.

## Practical Defaults

Use these defaults unless the local config says otherwise:

- Compile host: `jamin@100.89.114.123`
- Test host: `root@100.105.175.44`
- Onebuild command: `onebuild_GOGS_backend_self.sh`

Keep the skill tuned to this repository's fixed deployment path. Favor speed and directness over abstraction.
