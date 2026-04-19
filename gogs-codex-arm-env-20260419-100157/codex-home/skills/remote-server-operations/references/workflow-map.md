# Workflow Map

## Purpose

Use this reference when the repository already contains scripts and docs, and you need to pick the correct entrypoint without re-reading the entire project tree.

## Project Docs To Prefer

### Always read first

1. `README.md`
2. `.agent/local/90-project-specific.md`
3. `docs/2026-04-16-headscale-deployment-facts.md`

### Future deploy path

1. `docs/2026-04-17-one-click-redeploy-runbook.md`
2. `docs/2026-04-17-redeploy-readiness-checklist.md`
3. `docs/superpowers/specs/2026-04-17-one-click-future-stack-design.md`

### Cleanup or rollback path

1. `docs/2026-04-16-headscale-archive-and-cleanup.md`
2. `docs/2026-04-16-headscale-rollback-result.md`

## Script Entry Map

### Read-only preflight

1. `scripts/preflight-future-server.sh`

Use for:

1. host identity
2. OS and kernel
3. CPU, memory, disk, swap
4. listeners and firewall
5. existing Docker workloads

### Input validation

1. `scripts/validate-future-inputs.sh`

Use for:

1. local `.env.future.local` validation
2. placeholder detection
3. deploy blocking before remote mutation

### Full deploy

1. `scripts/deploy-future-stack.sh`

Use for:

1. package bundle upload
2. remote install
3. remote post-configure
4. automatic verify handoff

### Remote install internals

1. `scripts/remote-install-future-stack.sh`
2. `scripts/remote-configure-authentik.sh`

Use for:

1. package installation
2. config rendering
3. service startup
4. Authentik login links
5. Headscale OIDC application/provider convergence

### Independent verification

1. `scripts/verify-future-stack.sh`

Use for:

1. remote service state
2. local listeners
3. public health endpoints
4. Authentik application objects
5. Turnstile presence on enrollment and recovery flows

### Cleanup and rollback

1. `scripts/cleanup-headscale-remote.sh`

Use for:

1. removing only project-owned Headscale resources
2. pre and post Docker snapshot comparison
3. rollback evidence logging

## Strong Success Signals

Prefer these over vague log reading:

1. `systemctl is-active --quiet <service>`
2. `headscale configtest -c /etc/headscale/config.yaml`
3. `curl -fsS https://<domain>/health`
4. `curl -fsSI https://<domain>/derp/probe`
5. `docker compose ps --services --status running`
6. API lookup confirming expected objects exist

## Safety Reminders

1. Snapshot unrelated Docker workloads before cleanup or risky mutation.
2. Do not delete configs, services, users, or data you did not create for the current project task.
3. Keep secrets in local private env files or runtime-only remote files, not Git.
4. Update `docs/` whenever a newly confirmed fact changes redeploy, cleanup, or troubleshooting behavior.
