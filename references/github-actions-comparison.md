# GitHub Actions Comparison (customerio-skills vs roamresearch-skills)

This reference compares two real repositories and extracts reusable workflow patterns.

## Inputs Compared

- `customerio-skills/.github/workflows/ci.yml`
- `customerio-skills/.github/workflows/release-command.yml`
- `customerio-skills/.github/workflows/release.yml`
- `roamresearch-client-py/roamresearch-skills/.github/workflows/go-ci.yml`
- `roamresearch-client-py/roamresearch-skills/.github/workflows/release-command.yml`
- `roamresearch-client-py/roamresearch-skills/scripts/next-version.sh`

## CI Comparison

1. Trigger scope
- customerio: only `main` (`customerio-skills/.github/workflows/ci.yml:5`).
- roam: all branches (`roamresearch-client-py/roamresearch-skills/.github/workflows/go-ci.yml:5`).
- Reuse decision: default to all branches for early detection.

2. Go version strategy
- customerio: hardcoded `1.22` (`customerio-skills/.github/workflows/ci.yml:17`).
- roam: `go-version-file: go.mod` (`roamresearch-client-py/roamresearch-skills/.github/workflows/go-ci.yml:24`).
- Reuse decision: prefer `go-version-file` to reduce drift.

3. Dependency drift guard
- customerio: none.
- roam: `go mod tidy` + diff check (`roamresearch-client-py/roamresearch-skills/.github/workflows/go-ci.yml:28`).
- Reuse decision: keep this gate.

4. Static checks
- customerio: golangci action with `version: latest` (`customerio-skills/.github/workflows/ci.yml:56`).
- roam: `go vet` only (`roamresearch-client-py/roamresearch-skills/.github/workflows/go-ci.yml:43`).
- Reuse decision: use both vet and pinned linter; never use `latest`.

5. BDD strategy
- customerio: build binary then run BDD with `CIO_BINARY` (`customerio-skills/.github/workflows/ci.yml:39`).
- roam: run `-tags=bdd` tests directly (`roamresearch-client-py/roamresearch-skills/.github/workflows/go-ci.yml:50`).
- Reuse decision: keep BDD command configurable in template.

6. Extra artifacts
- customerio uploads coverage (`customerio-skills/.github/workflows/ci.yml:22`).
- roam does not.
- Reuse decision: coverage upload optional toggle.

## Release Command Comparison

1. Parse and authorization
- both validate command and author association (`customerio-skills/.github/workflows/release-command.yml:75`, `roamresearch-client-py/roamresearch-skills/.github/workflows/release-command.yml:69`).
- customerio supports case-insensitive command variants (`customerio-skills/.github/workflows/release-command.yml:31`).
- roam supports prerelease labels `alpha|beta|rc` (`roamresearch-client-py/roamresearch-skills/.github/workflows/release-command.yml:48`).

2. PR constraints
- customerio allows non-PR comments and falls back to `main` (`customerio-skills/.github/workflows/release-command.yml:94`).
- roam requires PR comments (`roamresearch-client-py/roamresearch-skills/.github/workflows/release-command.yml:76`).
- Reuse decision: prefer PR-only release comments to avoid accidental tagging.

3. Version/tag generation
- customerio computes next semver inline in workflow (`customerio-skills/.github/workflows/release-command.yml:167`).
- roam uses script `scripts/next-version.sh` (`roamresearch-client-py/roamresearch-skills/.github/workflows/release-command.yml:136`).
- Reuse decision: script-based version logic for easier testing and reuse.

4. Tag safety
- roam checks tag collision before push (`roamresearch-client-py/roamresearch-skills/.github/workflows/release-command.yml:144`).
- customerio does not have explicit pre-check in create step.
- Reuse decision: keep explicit collision check.

5. Comment reliability
- roam wraps comments as best-effort and uses `continue-on-error: true` (`roamresearch-client-py/roamresearch-skills/.github/workflows/release-command.yml:153`).
- customerio comments can fail the flow.
- Reuse decision: never fail release because issue comment failed.

## Release Build Comparison

1. Release build location
- customerio has dedicated tag workflow (`customerio-skills/.github/workflows/release.yml:1`).
- roam builds release in `release-command.yml` job `build-release` (`roamresearch-client-py/roamresearch-skills/.github/workflows/release-command.yml:187`).
- Reuse decision: split concerns; keep tag build in a separate `release-on-tag` workflow.

2. Artifact strategy
- customerio: GoReleaser (`customerio-skills/.github/workflows/release.yml:32`).
- roam: manual cross-build + tar + checksums + `softprops/action-gh-release` (`roamresearch-client-py/roamresearch-skills/.github/workflows/release-command.yml:207`).
- Reuse decision: default to GoReleaser, keep manual release as fallback option.

## Canonical Reuse Set

1. CI template with:
- all-branch triggers
- `go-version-file`
- tidy diff guard
- vet + tests + configurable BDD + build
- optional coverage upload

2. Release-command template with:
- PR comment parsing
- permission checks
- script-based versioning
- tag collision detection
- best-effort comments

3. Release-on-tag template with:
- full quality gate before publish
- GoReleaser publish path
- optional rerun via workflow_dispatch
4. Manual release-on-tag template with:
- matrix cross-build + archive naming
- explicit checksum generation
- softprops GitHub release upload
5. Shared naming contract with helpers:
- `release-naming.env`
- `scripts/init-release-naming.sh`
- `scripts/print-release-download.sh`
