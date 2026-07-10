# Complete Codex Launcher Design

## Goal

Make the repository able to reproduce the current Codex launch chain, not only
the `$HOME/.codex/path.sh` environment defaults. The repository must archive
and deploy the verified `$HOME/.local/bin/codex` wrapper together with the
existing global Agent tree.

## Source Layout

- `codex-home/` remains an exact deployable mirror of the selected
  `$HOME/.codex` files.
- `codex-launcher/codex` is the controlled copy of the verified
  `$HOME/.local/bin/codex` wrapper.
- `dist/codex-global-agent-tree.tar.gz` contains both the existing `.codex`
  payload at the archive root and `codex-launcher/codex`.

Keeping the wrapper outside `codex-home/` preserves the repository rule that
`codex-home/` mirrors `$HOME/.codex` without introducing files that belong
under `$HOME/.local/bin`.

## Packaging

`scripts/codex-agent-tree/package.sh` must:

1. Require `codex-launcher/codex` to exist and be executable.
2. Add `codex-launcher/codex` to the generated manifest.
3. Include the wrapper in the existing archive without changing the paths of
   the current `.codex` payload.
4. Continue excluding authentication, sessions, memories, caches, plugins,
   logs, state databases, and other runtime-only files.
5. Continue producing the SHA-256 checksum with macOS-compatible tooling.

## Deployment

`scripts/codex-agent-tree/deploy.sh` must support both source-tree and archive
deployment:

- The existing `--target PATH` continues to select the `.codex` destination.
- A new `--launcher-target PATH` selects the wrapper destination and defaults
  to `$HOME/.local/bin/codex`.
- The script verifies that the wrapper exists before changing either target.
- The script creates the wrapper destination directory, copies the wrapper,
  and sets mode `0755`.
- Existing runtime files under `$HOME/.codex` remain untouched.
- The final output reports both the `.codex` destination and launcher path.

The wrapper requires Bash and supports both macOS and WSL/Linux. User-home
lookup uses `dscl` on macOS and `getent passwd` on WSL/Linux, with `$HOME` as
the final fallback. Packaging and deployment scripts remain compatible with
macOS `/bin/sh`, BSD `tar`, BSD `mktemp`, system `rsync`, and `shasum`.

## Documentation

`README.md` must distinguish the two startup components:

- `codex-home/path.sh` supplies PATH and default environment values.
- `codex-launcher/codex` is the actual command wrapper that applies defaults
  and performs the existing startup checks and synchronization.

The complete-deployment examples must document `--launcher-target` for an
isolated or custom installation, and the deployment-boundary section must list
the wrapper as an overwritten file.

## Verification

The change is accepted only when all of the following pass:

1. The initial imported `codex-launcher/codex` is byte-for-byte identical to
   the verified live wrapper; subsequent platform fixes remain surgical and
   independently verified on macOS and the WSL/Linux HOME-resolution branch.
2. `bash -n codex-launcher/codex` and `sh -n` on both helper scripts succeed.
3. Packaging succeeds, the checksum validates, and the archive contains the
   wrapper with executable permissions.
4. Source-tree deployment to temporary targets produces files identical to
   the repository sources.
5. Archive deployment to temporary targets produces the same result.
6. The deployed temporary wrapper retains mode `0755` and still contains the
   `gpt-5.6-sol` / `high` default injection path.
7. `git diff --check` succeeds and only the launcher, packaging, deployment,
   documentation, design, plan, and generated distribution files change.
8. A fresh macOS login shell resolves `$HOME/.local/bin/codex` without zsh
   completion errors, and a controlled `getent` fixture exercises the
   WSL/Linux HOME-resolution branch.

## Scope Boundaries

- Do not archive credentials or mutable Codex runtime state.
- Do not broadly refactor the imported wrapper; only minimal, verified
  cross-platform compatibility fixes are allowed.
- Do not change the real Codex npm installation under
  `$HOME/.codex/npm-global`.
- Do not change the current live wrapper during temporary deployment tests.
