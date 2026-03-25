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

> **Steps 1–5 create the project scaffold. Do NOT write any Go command code until all scaffold files exist and `make build` succeeds with a skeleton binary.**

1. Confirm target commands, output contract, and release policy.
2. If you only have API docs, generate implementation inputs from `openapi.json`:
   - `scripts/openapi-bootstrap.sh <openapi.json> <output-dir>`
3. **Create `release-naming.env`** — run `scripts/init-release-naming.sh <repo-dir>` or copy from `assets/templates/release-naming.env`. Replace every `your-cli` placeholder with the actual CLI name. Verify all 5 variables are set.
4. **Initialize project files** — run `scripts/init-project-files.sh <repo-dir>`:
   - Copies Makefile, .gitignore, and README.md from `assets/templates/`.
   - Replace placeholders (`your-cli`, `OWNER/REPO`, `YOUR_SERVICE_NAME`) to match `release-naming.env`.
   - Copy `assets/templates/scripts/next-version.sh` to `scripts/next-version.sh` and `chmod +x`.
   - Copy `assets/templates/version.go` to `pkg/version/version.go` (or similar) and customize.
5. **Scaffold Go packages** (all of these, not just some):
   - `cmd/<cli-name>/main.go` — minimal entry point.
   - `internal/cmd/root.go` — `NewRootCmd` factory, global flags, exit codes.
   - `internal/client/client.go` — HTTP client skeleton.
   - `internal/model/` — at least one model file.
   - `internal/output/output.go` — `Formatter` skeleton.
   - `tests/bdd/features/` and `tests/bdd/steps/` — directories created.
   - Run `go mod init github.com/<owner>/<repo>` and `go mod tidy`.
   - **Checkpoint**: `make build` must succeed before proceeding.
   - Load `references/go-code-architecture.md` for exact patterns.
6. **Apply GitHub Actions** — copy all workflow files from `assets/templates/.github/workflows/`:
   - `go-ci.yml` (required)
   - `release-command.yml` (required)
   - `release-on-tag.yml` or `release-on-tag-manual.yml` (choose one)
   - Customize `BUILD_TARGET` and binary name references to match `release-naming.env`.
7. Initialize pre-commit gate with `scripts/init-prek.sh <repo-dir>`.
8. Run `prek validate-config` and `prek install --install-hooks`.
9. Implement commands, client methods, and models (the bulk of development).
10. Validate repository-specific commands (`go test`, BDD command, build path, release tool).
11. Run `scripts/audit-workflows.sh` and `scripts/audit-release-naming.sh` and fix all findings.
12. If the project is also an agent skill, scaffold `skills/<name>/SKILL.md` with command mapping, usage examples, and error handling rules.
13. **Run delivery verification** (see below) — every item must pass.

## Required CLI Contract

- Parseable output modes are mandatory (`--json`, `--plain`).
- `--token` flag must exist on the root command, falling back to `<SERVICE>_API_TOKEN` env var.
- Human hints/progress go to stderr, not stdout.
- `--jq` must only work when JSON output mode is enabled. Must be implemented using `itchyny/gojq` library — never shell out to external `jq`.
- Exit codes must be stable and script-safe:
  | Code | Meaning |
  |------|---------|
  | 0 | Success |
  | 1 | General error |
  | 2 | Auth failure (401/403) |
  | 3 | Not found (404) |
- Auth/connectivity check uses a `status` command (not `auth check` or similar).
- Credentials via environment variable named `<SERVICE>_API_TOKEN` (e.g. `READWISE_API_TOKEN`).
- `list` commands should accept `ls` as an alias.
- Command and subcommand names must match the API's own terminology. If the API endpoint is `/save/`, use `save`; if it is `/export/`, use `export`. Do not rename API verbs to generic CRUD terms (`create`, `read`, `update`, `delete`) unless the API itself uses those terms.

## Project Scaffold Contract

These files must exist before writing any Go code. They are not optional and must not be skipped.

### Required Files (copy from templates)

| File | Source Template | Action |
|------|---------------|--------|
| `release-naming.env` | `assets/templates/release-naming.env` | Copy, replace `your-cli` with actual CLI name |
| `Makefile` | `assets/templates/Makefile` | Copy, replace `your-cli` with actual CLI name |
| `.gitignore` | `assets/templates/.gitignore` | Copy as-is |
| `README.md` | `assets/templates/README.md` | Copy, customize for the project |
| `scripts/next-version.sh` | `assets/templates/scripts/next-version.sh` | Copy as-is, `chmod +x` |
| `.github/workflows/go-ci.yml` | `assets/templates/.github/workflows/go-ci.yml` | Copy, customize build target |
| `.github/workflows/release-command.yml` | `assets/templates/.github/workflows/release-command.yml` | Copy as-is |
| `.github/workflows/release-on-tag.yml` | `assets/templates/.github/workflows/release-on-tag.yml` | Copy as-is (or use `-manual` variant) |

### release-naming.env

Must contain all 5 variables — no variable may be left as placeholder:

```
CLI_NAME=<actual-cli-name>
BINARY_NAME=<actual-cli-name>
TAG_PREFIX=v
ARTIFACT_GLOB=<actual-cli-name>-*.tar.gz
BUILD_TARGET=./cmd/<actual-cli-name>
```

### Makefile

Must have these targets: `tidy`, `fmt`, `test`, `bdd-test`, `ci`, `build`, `cross-build`, `clean`.
The `ci` target must run: format check, `go vet`, unit tests, BDD tests, and build.

### README.md

Must include: project description, install instructions (release download + build from source), required configuration (env vars), command list, and usage examples.

## Code Architecture Contract

> See `references/go-code-architecture.md` for complete annotated examples.

### Package Layout

Every project must follow this structure:

- `cmd/<cli-name>/main.go` — minimal entry point (only calls `cmd.NewRootCmd()` + `cmd.ExitCode()`)
- `internal/cmd/` — all Cobra command factories and helpers
- `internal/client/` — HTTP client, params structs, typed errors
- `internal/model/` — response/request/update structs with JSON tags
- `internal/output/` — `Formatter` with JSON/plain/jq support
- `tests/bdd/` — BDD features and step definitions

### go.mod

- Module path must be `github.com/<owner>/<repo>` — never a bare name like `myservice`.

### Cobra Pattern

- **No `init()` functions.** No global `var rootCmd`.
- Every command is created by a factory function: `newXxxCmd() *cobra.Command`.
- Subcommands are registered inside their parent's factory via `cmd.AddCommand(newXxxCmd())`.

### Root Command

- `NewRootCmd()` is the only public factory in `internal/cmd/`.
- Must set `SilenceUsage: true` and `SilenceErrors: true`.
- Must define global persistent flags: `--token`, `--json`, `--plain`, `--jq`.
- Must have `PersistentPreRunE` that validates `--jq` requires `--json`.
- Must have unexported helpers: `getClient(cmd)` and `getFormatter(cmd)`.
- `--token` falls back to `<SERVICE>_API_TOKEN` environment variable.

### Exit Codes

Must define `ExitCode(err error) int` in `internal/cmd/root.go`:

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | General error |
| 2 | Auth failure (401/403) |
| 3 | Not found (404) |

### Subcommand Naming

- Match API brand terms — use the exact name the API uses (e.g., if the API calls it "Reader", use `reader`, not `document`; if the API endpoint is `/save/`, use `save`, not `create`).
- Every `list` subcommand must have `Aliases: []string{"ls"}`.
- Flags use **kebab-case** with human-friendly names (`--updated-after`, not `--updated_gt`).

### Command Depth

- Only create a subcommand group when a resource has **multiple distinct actions** (e.g., `reader list`, `reader get`, `reader save`).
- If an API operation stands alone with no sibling actions, expose it as a **top-level command** — do not wrap it in a single-child subcommand group. For example, if the API has one export endpoint, use `cli export`, not `cli export list`.
- The same applies to operations like daily review — `cli review` is correct; `cli review list` is wrong when there is only one action.

### Output Formatter

- Must live in `internal/output/output.go`.
- Must use `itchyny/gojq` for `--jq` filtering — never shell out to external `jq`.
- Required methods: `Print(w, data)`, `Hint(format, args...)`, `PrintMessage(w, msg)`.
- `Hint()` always writes to stderr.

### Client

- Params structs have an `encode() url.Values` method.
- Client methods accept params structs directly.
- `APIError` typed error with `StatusCode` field for exit code mapping.

### Models

- Response structs: every field must have a `json:"snake_case"` tag.
- Request structs: optional fields use `omitempty`.
- Update structs: use pointer fields (`*string`) + `omitempty` to distinguish "not set" from "empty".
- Use `PaginatedResponse[T]` generic for list endpoints.

### Dependencies

- Required: `github.com/spf13/cobra` and `github.com/itchyny/gojq`.

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

Before marking delivery complete, verify **every** item below. If any item fails, fix it before continuing.

### Scaffold files (must exist)

1. **release-naming.env**: Exists at repo root with all 6 variables (`CLI_NAME`, `BINARY_NAME`, `TAG_PREFIX`, `ARTIFACT_GLOB`, `BUILD_TARGET`, `VERSION_VAR_PATH`) — no placeholders.
2. **Makefile**: Exists at repo root with targets `ci`, `build`, `test`, `bdd-test`, `cross-build`, `clean`. Values must match `release-naming.env` and implement version embedding.
3. **.gitignore**: Exists, includes `bin/` and `dist/`.
4. **README.md**: Exists with install instructions, required configuration, command list, and usage examples.
5. **scripts/next-version.sh**: Exists and is executable.
6. **GitHub Actions**: `.github/workflows/go-ci.yml` exists. At least one release workflow (`release-on-tag.yml` or `release-on-tag-manual.yml`) exists. `release-command.yml` exists.
7. **Binary location**: `bin/` is in `.gitignore`. No compiled binaries at repo root.

### Code architecture (must pass)

8. **Package layout**: All required directories exist: `cmd/<name>/`, `internal/cmd/`, `internal/client/`, `internal/model/`, `internal/output/`.
9. **Cobra pattern**: No `func init()` in any file under `internal/cmd/`.
10. **go.mod module path**: Must be `github.com/<owner>/<repo>` — not a bare name.
11. **Output formatter**: `internal/output/output.go` exists and implements `Formatter`.
12. **Exit codes**: `ExitCode` function exists in `internal/cmd/root.go`.
13. **Required deps**: `go.mod` contains both `github.com/spf13/cobra` and `github.com/itchyny/gojq`.
14. **List aliases**: Every `list` subcommand has `Aliases: []string{"ls"}`.
15. **Flag naming**: No flags use underscores — use kebab-case (`--updated-after`, not `--updated_gt`).

### API and quality (must pass)

16. **API completeness**: Cross-check every operation in `openapi-command-plan.md` (or API docs). Every parameter the API accepts must have a corresponding CLI flag.
17. **Model JSON tags**: Every field in model structs under `internal/model/` must have a correct `json:"..."` tag matching the API response field name.
18. **Format check**: Run `gofmt -l ./cmd ./internal ./tests` and confirm zero output.
19. **Build check**: Run `make ci` and confirm it passes.
20. **Naming consistency**: All references to binary name, CLI name, and build target must match `release-naming.env`.
21. **Tests exist**: At least one `_test.go` file exists. Client package must have tests using `httptest`. Output package must have tests for `Formatter` (JSON, plain, and jq modes).
22. **BDD structure**: `tests/bdd/features/` contains at least one `.feature` file and `tests/bdd/steps/` contains at least one `_test.go` file.
23. **Command structure**: No single-child subcommand groups — if a resource has only one action, it must be a top-level command (e.g., `cli export`, not `cli export list`).

## What To Load

- For Go code architecture patterns and examples: `references/go-code-architecture.md`
- For side-by-side lessons and pitfalls: `references/github-actions-comparison.md`
- For rollout checklist: `references/github-actions-adoption-checklist.md`
- For OpenAPI-only delivery flow: `references/openapi-first-delivery.md`
- For packaging strategy and naming mapping: `references/release-packaging-strategies.md`
- For `prek` setup and commands: `references/prek-precommit.md`
- For copy-ready templates: `assets/templates/.github/workflows/*.yml`
- For standardized project structure: `assets/templates/Makefile`, `assets/templates/version.go`
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
