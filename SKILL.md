---
name: go-api-cli-playbook
description: Build and standardize Go API-to-CLI projects with stable machine-friendly output, layered tests (unit/BDD/integration), and reusable GitHub Actions CI/release workflows.
---

# Go API CLI Playbook

Use this skill when a Go project is converting an API into a CLI and you need production-grade engineering defaults.

## Outcomes

- Consistent CLI I/O contract for humans, scripts, and LLMs.
- OpenAPI-first delivery path from only `openapi.json`.
- Repeatable testing strategy: unit + BDD + opt-in integration.
- Reusable GitHub Actions workflow templates for CI and release.
- Reduced workflow drift by reusing templates and audit checks.
- Complete project scaffold (Makefile, .gitignore, README).
- Release flow that passes these acceptance rules:
  - PR comment `!release [patch|minor|major]` works.
  - Manual workflow dispatch works.
  - Every publish creates `vX.Y.Z` tag and GitHub Release.
  - Artifacts are multi-platform and unpack to one binary name.
  - Changelog is generated and used as GitHub Release notes.

## Workflow

1. Confirm target commands, output contract, and release policy.
2. If you only have API docs, generate implementation inputs from `openapi.json`:
   - `scripts/openapi-bootstrap.sh <openapi.json> <output-dir>`
3. Define release naming contract in one place with `scripts/init-release-naming.sh <repo-dir>`.
4. Initialize project files with `scripts/init-project-files.sh <repo-dir>`:
   - Copies Makefile, .gitignore, and README.md templates.
   - Customize placeholders (`your-cli`, `OWNER/REPO`, `YOUR_SERVICE_NAME`) to match `release-naming.env`.
5. Initialize pre-commit gate with `scripts/init-prek.sh <repo-dir>`.
6. Run `prek validate-config` and `prek install --install-hooks`.
7. Apply the GitHub Actions baseline from `assets/templates/.github/workflows/`.
8. Choose one packaging strategy:
   - Canonical manual packaging (`release-on-tag.yml`)
   - Alternative manual packaging variant (`release-on-tag-manual.yml`)
9. Adapt versioning with `assets/templates/scripts/next-version.sh`.
10. Validate repository-specific commands (`go test`, BDD command, build path, release tool).
11. Run `scripts/audit-workflows.sh` and `scripts/audit-release-naming.sh` and fix all findings.
12. If the project is also an agent skill, scaffold `skills/<name>/SKILL.md` with command mapping, usage examples, and error handling rules.
13. Run delivery verification (see below).

## Required CLI Contract

- Parseable output modes are mandatory (`--json`, `--plain`).
- Human hints/progress go to stderr, not stdout.
- `--jq` must only work when JSON output mode is enabled.
- Exit codes must be stable and script-safe.
- Auth/connectivity check uses a `status` command (not `auth check` or similar).
- Credentials via environment variable named `<SERVICE>_API_TOKEN` (e.g. `READWISE_API_TOKEN`).
- `list` commands should accept `ls` as an alias.

## Test Contract

- Run `prek run --all-files` before any test command.
- Unit tests in default `go test ./...` path.
- BDD path must be explicit and reproducible in CI.
- Integration tests must be opt-in (tagged and credential-gated).

## GitHub Actions Contract

- CI workflow must run formatting, vet/lint, tests, and build.
- CI build step must read `BUILD_TARGET` and `BINARY_NAME` from `release-naming.env`, output to `bin/`.
- Release workflow must support both:
  - PR comment trigger (`!release <patch|minor|major>`)
  - Manual workflow dispatch
- Release command workflow should parse/authorize/create tag, then explicitly dispatch `release-on-tag.yml`.
- Tag-triggered release workflow should build artifacts, generate changelog, and publish release.
- Commenting back to PR/issue should be best-effort (`continue-on-error: true`).

## Release Naming Contract (Required)

- Keep these values as single source of truth:
  - `CLI_NAME`
  - `BINARY_NAME`
  - `TAG_PREFIX`
  - `ARTIFACT_GLOB`
  - `BUILD_TARGET`
- Any `gh release` command must read from this contract, never hardcode old names.
- For download docs/examples, generate command via `scripts/print-release-download.sh`.

## OpenAPI-First Contract (Required When Spec-Driven)

- Minimum input: one OpenAPI JSON file.
- Run `scripts/openapi-bootstrap.sh` to produce:
  - operations inventory (`openapi-operations.tsv`)
  - command plan (`openapi-command-plan.md`)
  - test matrix (`openapi-test-matrix.md`)
- Use generated operation IDs as canonical command intent when API docs are the only source.

## Delivery Verification (Required Before Done)

Before marking delivery complete, verify all of the following:

1. **API completeness**: Cross-check every operation in `openapi-command-plan.md` (or API docs). Confirm all query parameters, request body fields, and response fields are implemented — not just the happy path. Every parameter the API accepts must have a corresponding CLI flag.
2. **Model JSON tags**: Every field in model structs under `internal/model/` must have a correct `json:"..."` tag matching the API response field name.
3. **Format check**: Run `gofmt -l ./cmd ./internal ./tests` and confirm zero output.
4. **Build check**: Run `make ci` and confirm it passes.
5. **Naming consistency**: All references to binary name, CLI name, and build target must match `release-naming.env`.

## What To Load

- For side-by-side lessons and pitfalls: `references/github-actions-comparison.md`
- For rollout checklist: `references/github-actions-adoption-checklist.md`
- For OpenAPI-only delivery flow: `references/openapi-first-delivery.md`
- For packaging strategy and naming mapping: `references/release-packaging-strategies.md`
- For `prek` setup and commands: `references/prek-precommit.md`
- For copy-ready templates: `assets/templates/.github/workflows/*.yml`
- For tag versioning script: `assets/templates/scripts/next-version.sh`
- For naming contract template: `assets/templates/release-naming.env`
- For a ready `prek` config: `assets/templates/prek.toml`
- For Makefile template: `assets/templates/Makefile`
- For .gitignore template: `assets/templates/.gitignore`
- For README template: `assets/templates/README.md`
- For download command helper: `scripts/print-release-download.sh`
- For OpenAPI bootstrap: `scripts/openapi-bootstrap.sh`
- For project files bootstrap: `scripts/init-project-files.sh`
- For bootstrap helper script: `scripts/init-prek.sh`
- For naming contract bootstrap: `scripts/init-release-naming.sh`
- For naming drift audit: `scripts/audit-release-naming.sh`
