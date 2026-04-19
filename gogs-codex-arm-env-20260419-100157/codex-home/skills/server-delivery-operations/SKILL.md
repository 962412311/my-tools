---
name: server-delivery-operations
description: Use when operating Linux servers over SSH for staged delivery workflows such as preflight, systemd deploys, Docker Compose deploys, reverse-proxy cutovers, verification, cleanup, or rollback.
---

# Server Delivery Operations

## Overview

Use this skill for cross-project remote server delivery work.

It is intentionally generic:

1. no project-specific paths
2. no repo-specific service names
3. no assumption that the target stack is Headscale, Authentik, or any other specific app

The core model is:

1. turn remote work into explicit stages
2. prefer strong verification over log-reading guesses
3. protect unrelated workloads
4. keep chat low-noise and logs structured
5. write down newly confirmed facts when the repo expects operational documentation

## When To Use

Use this skill when the task involves any of these:

1. SSH-based Linux server preflight
2. deploying or updating services managed by `systemd`
3. deploying or updating applications managed by `docker compose`
4. changing or introducing a reverse proxy such as `Caddy`, `nginx`, or `Traefik`
5. verifying a public service after remote changes
6. cleaning up or rolling back only the resources introduced by the current delivery workflow

Do not use this skill for:

1. pure local development with no remote server impact
2. exploratory shell sessions that do not need repeatability

## Required Inputs

Before acting, confirm or derive:

1. target host or SSH alias
2. workflow type:
   - `preflight`
   - `deploy`
   - `verify`
   - `cleanup`
   - `rollback`
3. deployment model:
   - `systemd`
   - `docker-compose`
   - `reverse-proxy`
   - mixed stack
4. protection scope:
   - does the server already host unrelated workloads
   - are there protected ports, containers, services, or data paths

If the repository already has scripts or docs for this workflow, use them instead of inventing a parallel manual flow.

For the condensed scenario guide, read:

1. `references/scenario-map.md`

## Stage Model

Always break the work into explicit stages.

### 1. Preflight

Goal: confirm current state before mutation.

Minimum checks:

1. host identity
2. OS and package manager
3. CPU, memory, disk, swap
4. listeners and firewall state
5. running services
6. running containers if Docker is present

### 2. Deploy

Goal: apply the smallest reproducible change set.

Default rules:

1. validate inputs first
2. prefer repo-owned scripts
3. keep detailed output in log files
4. do not mix deploy and verify into an unstructured one-liner

### 3. Verify

Goal: prove the new state with strong evidence.

Good evidence:

1. `systemctl is-active --quiet <service>`
2. `docker compose ps --services --status running`
3. config tests such as `nginx -t` or app-specific config validators
4. local listener checks with `ss`
5. public endpoint checks with `curl`

### 4. Cleanup Or Rollback

Goal: revert only what the current workflow introduced.

Default rules:

1. snapshot protected workloads first when practical
2. identify exact resources to remove
3. verify unrelated workloads are unchanged afterward

## Common Delivery Scenarios

### Systemd-managed service

Use when:

1. shipping a binary, package, or config onto the host
2. enabling or restarting a long-lived service

Expected evidence:

1. unit file exists where expected
2. config test passes if supported
3. `systemctl is-active --quiet <service>` succeeds
4. expected listener or health endpoint responds

### Docker Compose application

Use when:

1. the stack is containerized
2. the deploy path is `docker compose pull && up -d`

Expected evidence:

1. compose file renders correctly
2. required containers are running
3. required volumes and env files are present
4. public or local health checks pass

### Reverse-proxy cutover

Use when:

1. introducing or modifying `Caddy`, `nginx`, or similar
2. routing multiple services behind one edge

Expected evidence:

1. proxy config syntax check passes
2. TLS listener is active
3. host-based routing returns the expected upstream
4. WebSocket-supporting apps still function when required

### Cleanup / rollback

Use when:

1. you must remove project-owned resources
2. a deploy must be reverted without disturbing other workloads

Expected evidence:

1. removed services are actually absent or stopped
2. protected workloads are still present and healthy
3. evidence is written to logs and docs if the repo tracks ops state

## Safety Rules

1. Default to read-only inspection before mutation.
2. Never treat “no stderr output” as success.
3. Never restart or delete unrelated services to make your deploy easier.
4. Never delete configs, users, groups, containers, or volumes unless you can attribute them to the current workflow.
5. Keep secrets out of Git and out of long-lived docs.

## Logging Rules

1. Use stage-named logs such as:
   - `preflight`
   - `build`
   - `upload`
   - `remote-install`
   - `verify`
   - `cleanup`
2. Keep chat summaries short:
   - `PASS/FAIL`
   - critical result
   - log path
3. If a stage fails, show the smallest useful tail, not the entire log.

## Documentation Rules

If the repository expects operational knowledge to live in versioned docs:

1. update facts when a new environment truth is confirmed
2. update runbooks when the execution path changes
3. update rollback docs when cleanup or revert logic changes

If the repository has no such practice, at least record:

1. what was changed
2. how it was verified
3. how to roll it back

## Completion Checklist

Do not call the task complete until all applicable items are true:

1. the chosen stage chain actually ran
2. verification used fresh evidence
3. unrelated workloads were protected or compared when risk existed
4. docs or operational notes were updated if the repo expects them
