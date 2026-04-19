---
name: remote-server-operations
description: Use when operating Linux servers for this repository over SSH, especially when you need the repo-specific docs, scripts, deployment entrypoints, and protected-workload rules on top of the generic server-delivery workflow.
---

# Remote Server Operations

## Overview

Use this skill as the repository-specific overlay for remote server work in this project.

If the generic skill is also available, pair it with:

1. `server-delivery-operations`

That generic skill covers the cross-project method. This skill narrows the work onto this repository's:

1. docs
2. scripts
3. topology
4. protected-resource boundaries

## When To Use

Use this skill when the task involves any of these:

1. SSHing into a Linux server for preflight, deployment, verification, rollback, cleanup, migration, or service repair
2. Operating a server where unrelated workloads already exist and must not be disturbed
3. Turning a noisy remote workflow into `preflight / deploy / verify / rollback` stages
4. Capturing environment facts, deployment results, or rollback evidence into local Markdown docs
5. Reusing project-owned scripts such as preflight, deploy, verify, or cleanup entrypoints

Do not use this skill for:

1. pure code-only changes with no server impact
2. casual shell exploration that has no repeatability or documentation requirement

## Required Inputs

Before taking action, confirm or derive these from local context:

1. target host or SSH alias
2. workflow type:
   - `preflight`
   - `deploy`
   - `verify`
   - `cleanup`
   - `rollback`
3. current project entrypoints under `docs/`, `scripts/`, and `templates/`
4. whether the server already hosts unrelated protected workloads

## Read First

Read the latest project state before touching a server:

1. `README.md`
2. `.agent/local/90-project-specific.md`
3. `docs/2026-04-16-headscale-deployment-facts.md`

Then load the workflow-specific docs as needed:

1. future deployment:
   - `docs/2026-04-17-one-click-redeploy-runbook.md`
   - `docs/2026-04-17-redeploy-readiness-checklist.md`
2. future deploy design:
   - `docs/superpowers/specs/2026-04-17-one-click-future-stack-design.md`
3. cleanup or rollback:
   - `docs/2026-04-16-headscale-archive-and-cleanup.md`
   - `docs/2026-04-16-headscale-rollback-result.md`

If you only need the condensed map of which doc or script to use next, read:

1. `references/workflow-map.md`

## Core Workflow

Always force the work into explicit stages.

### 1. Preflight

Goal: confirm environment facts before making changes.

Default actions:

1. prefer read-only checks first
2. capture listeners, services, firewall state, Docker containers, disk, memory, swap
3. write evidence into `logs/`
4. update Markdown facts if anything new is confirmed

Preferred repo entrypoint:

1. `scripts/preflight-future-server.sh`

### 2. Deploy

Goal: use the smallest reproducible entrypoint that can carry the full workflow.

Default actions:

1. validate inputs first
2. use repo-owned deployment scripts
3. keep detailed output in stage logs instead of chat
4. avoid inventing a second deployment path if one already exists in the repo

Preferred repo entrypoints:

1. `scripts/validate-future-inputs.sh`
2. `scripts/deploy-future-stack.sh`
3. `scripts/remote-install-future-stack.sh`
4. `scripts/remote-configure-authentik.sh`

### 3. Verify

Goal: prove the deployment state with strong evidence.

Default actions:

1. check service state with commands, not assumptions
2. verify public endpoints and local listeners
3. verify expected application objects when the stack includes APIs
4. record the outcome in docs if it changes the known state

Preferred repo entrypoint:

1. `scripts/verify-future-stack.sh`

### 4. Cleanup Or Rollback

Goal: revert only the resources created by the current workflow.

Default actions:

1. identify the exact resources introduced by the project
2. snapshot protected workloads before cleanup when relevant
3. compare pre and post state for unrelated services
4. never remove unrelated containers, services, configs, or data
5. archive cleanup evidence in docs and logs

Preferred repo entrypoint:

1. `scripts/cleanup-headscale-remote.sh`

## Safety Rules

1. Default to read-only inspection before any remote mutation.
2. Never treat “no error printed” as success; require a strong verification signal.
3. Never remove or restart unrelated services just to make your deployment easier.
4. If the server hosts other Docker workloads, snapshot them before cleanup or risky changes.
5. Keep secrets out of Git and out of Markdown; document generation method and metadata only.
6. When a new fact affects redeploy, rollback, or troubleshooting, write it into project docs in the same turn.

## Logging Rules

1. Keep detailed execution output under `logs/<workflow>/`.
2. Use short `PASS/FAIL + key result + log path` summaries in chat.
3. Prefer stage names like:
   - `preflight`
   - `upload`
   - `remote-install`
   - `post-config`
   - `verify`
   - `cleanup`

## Project-Specific Defaults

For this repository, prefer these existing assets before inventing new ones:

1. `templates/future-redeploy.env.example`
2. `templates/future-stack/`
3. `scripts/preflight-future-server.sh`
4. `scripts/deploy-future-stack.sh`
5. `scripts/verify-future-stack.sh`
6. `scripts/cleanup-headscale-remote.sh`

For a condensed selection guide, use:

1. `references/workflow-map.md`

## Completion Checklist

Do not call the remote server task complete until all applicable items are true:

1. the relevant repo script or command actually ran
2. service or endpoint verification passed with fresh evidence
3. new facts or results were written into local Markdown if they matter later
4. Git-visible assets that define the workflow were updated when needed
5. unrelated services were confirmed unchanged if the task had rollback or cleanup risk
