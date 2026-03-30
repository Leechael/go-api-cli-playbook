---
name: go-api-cli-playbook
description: Build and standardize Go API-to-CLI projects with scaffold, CI, release workflows, Go-specific engineering defaults, and agent-friendly CLI UX contracts.
---

# Go API CLI Playbook

Use this skill when a Go project is converting an API into a CLI and needs production-grade engineering defaults.

**Start here:** load `references/agent-friendly-cli.md` and complete the Phase 1 design contract before writing any Go code.

## Outcomes

- Complete project scaffold (Makefile, .gitignore, README).
- OpenAPI-first delivery path from only `openapi.json`.
- Repeatable testing: unit + BDD + opt-in integration.
- Reusable GitHub Actions templates for CI and release.
- Release flow: PR comment `!release [patch|minor|major]`, manual dispatch, multi-platform artifacts, changelog notes.

## Workflow

> **Steps 1–8 are mandatory bootstrap. Do NOT implement feature commands until scaffold files exist, `prek` hooks are installed, and `make build` passes on a skeleton binary.**

1. Load `references/agent-friendly-cli.md`. Freeze command taxonomy, output samples, and behavior semantics before writing code.
2. (OpenAPI-driven) Run `scripts/openapi-bootstrap.sh <openapi.json> <output-dir>` to produce operations inventory, command plan, and test matrix.
3. Create `release-naming.env` — run `scripts/init-release-naming.sh <repo-dir>` or copy from `assets/templates/release-naming.env`. Replace all `your-cli` placeholders. Verify all 5 variables are set.
4. Initialize project files — run `scripts/init-project-files.sh <repo-dir>`. Replaces placeholders in Makefile, README, prek.toml to match `release-naming.env`.
5. Scaffold Go packages — `cmd/<cli>/main.go`, `internal/cmd/root.go`, `internal/client/client.go`, `internal/model/`, `internal/output/output.go`, `tests/bdd/`. Run `go mod init` and `go mod tidy`. **Checkpoint: `make build` must pass before continuing.** See `references/go-code-architecture.md`.
6. Apply GitHub Actions — copy `go-ci.yml`, `release-command.yml`, and one release-on-tag workflow from `assets/templates/.github/workflows/`. Customize `BUILD_TARGET` to match `release-naming.env`.
7. Initialize pre-commit gate — run `scripts/init-prek.sh <repo-dir>` if `prek.toml` is missing.
8. Run `prek validate-config`, `prek install --install-hooks`, `prek run --all-files`. Confirm `.git/hooks/pre-commit` and `.git/hooks/pre-push` exist.
9. Implement commands, client methods, and models.
10. Validate: `go test ./...`, BDD command, `make ci`.
11. Run `scripts/audit-workflows.sh` and `scripts/audit-release-naming.sh`. Fix all findings.
12. (Agent skill) Scaffold `skills/<name>/SKILL.md` with command mapping, usage examples, and error handling rules.
13. Run `references/delivery-checklist.md` — every item must pass before done.

## Required CLI Contract

- Output modes `--json` and `--plain` are mandatory.
- `--jq` via `itchyny/gojq` only — never shell out.
- `--token` falls back to `<SERVICE>_API_TOKEN` env var.
- Hints and progress go to stderr, not stdout.
- Connectivity check uses `status` command (not `auth check`).
- `list` commands must have `ls` alias.
- Command names match API terminology — no CRUD genericization.
- Exit codes: `0` success, `1` error, `2` auth failure (401/403), `3` not found (404).

## What To Load

- `references/agent-friendly-cli.md` — CLI UX design contract, output format, help system, agent-friendly review checklist
- `references/go-code-architecture.md` — Go code patterns and annotated examples
- `references/delivery-checklist.md` — full delivery verification checklist
- `references/github-actions-comparison.md` — side-by-side lessons and pitfalls
- `references/github-actions-adoption-checklist.md` — rollout checklist
- `references/openapi-first-delivery.md` — OpenAPI-only delivery flow
- `references/release-packaging-strategies.md` — packaging strategy and naming mapping
- `references/prek-precommit.md` — prek setup and commands
- `assets/templates/.github/workflows/` — copy-ready workflow files
- `assets/templates/Makefile`, `assets/templates/version.go` — standardized project structure
- `assets/templates/scripts/next-version.sh` — tag versioning script
- `assets/templates/release-naming.env` — naming contract template
- `assets/templates/prek.toml` — ready prek config
- `scripts/print-release-download.sh` — download command generator
- `scripts/openapi-bootstrap.sh` — OpenAPI bootstrap
- `scripts/init-project-files.sh` — project files bootstrap
- `scripts/init-prek.sh` — prek bootstrap
- `scripts/init-release-naming.sh` — naming contract bootstrap
- `scripts/audit-release-naming.sh` — naming drift audit
