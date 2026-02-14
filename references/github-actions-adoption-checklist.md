# GitHub Actions Adoption Checklist

Use this checklist after copying templates.

## Acceptance Criteria

1. PR comment `!release [patch|minor|major]` triggers release flow.
2. Manual workflow run (`Release` workflow_dispatch) also triggers release flow.
3. Publish always creates `vX.Y.Z` tag and GitHub Release.
4. Multi-platform artifacts extract to the same binary name.
5. Release artifacts include `CHANGELOG.md`.
6. GitHub Release body uses changelog content.
7. Skill docs use valid `gh release download` commands derived from naming contract.

## Pre-Test Gate (prek)

1. Copy `assets/templates/prek.toml` to target repo root as `prek.toml`.
2. Run `prek validate-config`.
3. Run `prek install --install-hooks`.
4. Run `prek run --all-files` before tests locally and in CI.

## Release Naming Contract

1. Copy `assets/templates/release-naming.env` to target repo root.
2. Set `CLI_NAME`, `BINARY_NAME`, `ARTIFACT_GLOB`, `BUILD_TARGET`.
3. Keep `TAG_PREFIX=v` unless migration constraints require otherwise.
4. Ensure workflows and scripts read values from `release-naming.env` instead of hardcoded names.

## Release Workflow Checks

1. `release-command.yml` supports:
   - `issue_comment`
   - `pull_request_review_comment`
   - `workflow_dispatch`
2. Parser enforces `!release <patch|minor|major>` case-insensitively.
3. Tag creation step checks collision before push.
4. After tag creation, workflow dispatches `release-on-tag.yml`.
5. `release-on-tag.yml`:
   - builds darwin/linux and amd64/arm64 artifacts
   - packs binary name from `BINARY_NAME`
   - generates `dist/CHANGELOG.md`
   - publishes release with `body_path: dist/CHANGELOG.md`

## Download Command Consistency

1. Never hardcode artifact names in skill docs.
2. Generate command via `scripts/print-release-download.sh <tag>`.
3. Validate examples against `ARTIFACT_GLOB`.

## Final Audit Commands

1. `scripts/audit-workflows.sh <repo-dir>`
2. `scripts/audit-release-naming.sh <repo-dir>`
