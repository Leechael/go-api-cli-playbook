---
name: go-api-cli-playbook
description: Build and standardize Go API-to-CLI projects with stable machine-friendly output, layered tests (unit/BDD/integration), and reusable GitHub Actions CI/release workflows.
---

# Go API CLI Playbook

Use this skill when a Go project is converting an API into a CLI and you need production-grade engineering defaults.

## Outcomes

- Consistent CLI I/O contract for humans, scripts, and LLMs.
- Repeatable testing strategy: unit + BDD + opt-in integration.
- Reusable GitHub Actions workflow templates for CI and release.
- Reduced workflow drift by reusing templates and audit checks.

## Workflow

1. Confirm target commands, output contract, and release policy.
2. Define release naming contract in one place with `scripts/init-release-naming.sh <repo-dir>`.
3. Initialize pre-commit gate with `scripts/init-prek.sh <repo-dir>`.
4. Run `prek validate-config` and `prek install --install-hooks`.
5. Apply the GitHub Actions baseline from `assets/templates/.github/workflows/`.
6. Choose one packaging strategy:
   - GoReleaser publish (`release-on-tag.yml`)
   - Manual archive + upload (`release-on-tag-manual.yml`)
7. Adapt versioning with `assets/templates/scripts/next-version.sh`.
8. Validate repository-specific commands (`go test`, BDD command, build path, release tool).
9. Run `scripts/audit-workflows.sh` and `scripts/audit-release-naming.sh` and fix all findings.

## Required CLI Contract

- Parseable output modes are mandatory (`--json`, `--plain`).
- Human hints/progress go to stderr, not stdout.
- `--jq` must only work when JSON output mode is enabled.
- Exit codes must be stable and script-safe.

## Test Contract

- Run `prek run --all-files` before any test command.
- Unit tests in default `go test ./...` path.
- BDD path must be explicit and reproducible in CI.
- Integration tests must be opt-in (tagged and credential-gated).

## GitHub Actions Contract

- CI workflow must run formatting, vet/lint, tests, and build.
- Release command workflow should only parse/validate and create tags.
- Tag-triggered release workflow should build artifacts and publish release.
- Commenting back to PR/issue should be best-effort (`continue-on-error: true`).

## Release Naming Contract (Required)

- Keep these values as single source of truth:
  - `CLI_NAME`
  - `BINARY_NAME`
  - `TAG_PREFIX`
  - `ARTIFACT_GLOB`
- Any `gh release` command must read from this contract, never hardcode old names.
- For download docs/examples, generate command via `scripts/print-release-download.sh`.

## What To Load

- For side-by-side lessons and pitfalls: `references/github-actions-comparison.md`
- For rollout checklist: `references/github-actions-adoption-checklist.md`
- For packaging strategy and naming mapping: `references/release-packaging-strategies.md`
- For `prek` setup and commands: `references/prek-precommit.md`
- For copy-ready templates: `assets/templates/.github/workflows/*.yml`
- For tag versioning script: `assets/templates/scripts/next-version.sh`
- For naming contract template: `assets/templates/release-naming.env`
- For a ready `prek` config: `assets/templates/prek.toml`
- For download command helper: `scripts/print-release-download.sh`
- For bootstrap helper script: `scripts/init-prek.sh`
- For naming contract bootstrap: `scripts/init-release-naming.sh`
- For naming drift audit: `scripts/audit-release-naming.sh`
