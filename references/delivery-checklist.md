# Delivery Checklist

Before marking delivery complete, verify every item below. Fix failures before continuing.

Run the review checklist in `references/agent-friendly-cli.md` for UX, output format, and help system items.

## Scaffold files

- [ ] **release-naming.env** — exists at repo root, all 5 variables set, no placeholders
- [ ] **Makefile** — targets `ci`, `build`, `test`, `bdd-test`, `cross-build`, `clean` exist; values match `release-naming.env`
- [ ] **.gitignore** — includes `bin/` and `dist/`
- [ ] **README.md** — includes install instructions, required env vars, command list, usage examples
- [ ] **prek.toml** — exists at repo root, `prek validate-config` passes
- [ ] **scripts/next-version.sh** — exists and is executable
- [ ] **GitHub Actions** — `go-ci.yml`, `release-command.yml`, and at least one release-on-tag workflow exist
- [ ] **Binary location** — `bin/` is in `.gitignore`; no compiled binaries at repo root

## Code architecture

- [ ] **Package layout** — `cmd/<name>/`, `internal/cmd/`, `internal/client/`, `internal/model/`, `internal/output/` all exist
- [ ] **Cobra pattern** — no `func init()` in any file under `internal/cmd/`
- [ ] **go.mod module path** — `github.com/<owner>/<repo>`, not a bare name
- [ ] **Output formatter** — `internal/output/output.go` implements `Formatter` with `Print`, `Hint`, `PrintMessage`
- [ ] **Exit codes** — `ExitCode(err error) int` exists in `internal/cmd/root.go`
- [ ] **Required deps** — `go.mod` contains `github.com/spf13/cobra` and `github.com/itchyny/gojq`
- [ ] **List aliases** — every `list` subcommand has `Aliases: []string{"ls"}`
- [ ] **Flag naming** — no underscores in flag names; use kebab-case
- [ ] **Command structure** — no single-child subcommand groups

## API and quality

- [ ] **API completeness** — every parameter in API docs has a corresponding CLI flag
- [ ] **Model JSON tags** — every model struct field has a correct `json:"..."` tag matching the API field name
- [ ] **Pre-test gate** — `prek install --install-hooks` run; `.git/hooks/pre-commit` and `.git/hooks/pre-push` exist
- [ ] **Pre-commit run** — `prek run --all-files` passes
- [ ] **Format check** — `gofmt -l ./cmd ./internal ./tests` outputs nothing
- [ ] **Build check** — `make ci` passes
- [ ] **Naming consistency** — binary name, CLI name, build target all match `release-naming.env`
- [ ] **Tests exist** — at least one `_test.go`; client tests use `httptest`; output tests cover JSON, plain, and jq modes
- [ ] **BDD structure** — `tests/bdd/features/` has at least one `.feature`; `tests/bdd/steps/` has at least one `_test.go`

## Help system

- [ ] **docs/help structure** — `docs/help/embed.go` and `docs/help/topics/exit-codes.md` exist
- [ ] **exit-codes sync** — every exit code in `internal/cmd/root.go` has a row in `docs/help/topics/exit-codes.md`
- [ ] **HELP TOPICS block** — root `--help` output includes a `HELP TOPICS` section listing at least `exit-codes`
- [ ] **help routing** — `<cli> help exit-codes` prints content; `<cli> help unknown-xyz` exits non-zero and lists available topics
