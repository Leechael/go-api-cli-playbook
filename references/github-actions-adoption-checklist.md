# GitHub Actions Adoption Checklist

Use this checklist after copying templates.

## Pre-Test Gate (prek)

1. Copy `assets/templates/prek.toml` to target repo root as `prek.toml`.
2. Run `prek validate-config`.
3. Run `prek install --install-hooks`.
4. Run `prek run --all-files` before any test command locally.
5. Keep CI pre-test gate enabled when `prek.toml` exists.

## CI

1. Set the correct CLI build path in `go build -v ./cmd/<your-cli>`.
2. Set BDD command:
- Binary mode example: `CIO_BINARY=$PWD/cio go test -v ./test/...`
- Tag mode example: `go test -tags=bdd ./tests/bdd/... -count=1`
3. Ensure formatting paths match repository layout.
4. Pin linter versions; do not use `latest`.
5. Confirm `permissions: contents: read` is present.

## Release Command

1. Copy `assets/templates/release-naming.env` to repo root and set values.
2. Choose release tag prefix (for example: `v` or `roam-cli-v`).
3. Ensure `TAG_PREFIX` in workflow matches `release-naming.env`.
4. Ensure `scripts/next-version.sh` input uses the same `TAG_PREFIX`.
5. Confirm `!release` grammar and prerelease policy.
6. Ensure `!release` detection is case-insensitive in parser logic (for example `!release`, `!Release`, `!RELEASE`).
7. Keep PR-only gating for issue comment release commands.
8. Verify fork PR handling is blocked.
9. Ensure tag collision check exists before pushing.
10. Keep comment steps as best-effort.

## Release Packaging

1. Pick only one default publish path:
- GoReleaser (`release-on-tag.yml`)
- Manual cross-build (`release-on-tag-manual.yml`)
2. Ensure artifact filenames match `ARTIFACT_GLOB`.
3. Ensure docs/examples for `gh release download` use naming contract variables.
4. Use `scripts/print-release-download.sh <tag>` to print a correct command template.

## Release On Tag

1. Confirm tag glob matches `TAG_PREFIX`.
2. Run full quality gate (`make ci` or equivalent) before publish.
3. Ensure release tooling is pinned (GoReleaser action + version).
4. Confirm release artifacts list is complete and matches `ARTIFACT_GLOB`.
5. Validate changelog/release notes strategy.

## Common Failure Patterns To Catch Early

1. Workflow parses command but has insufficient `issues` permission to comment.
2. Workflow uses fixed Go version that drifts from `go.mod`.
3. BDD command differs between local and CI and silently rots.
4. Inline version bump logic diverges across workflows.
5. Tag prefix in docs and workflow are different.
6. `gh release download` examples still use old binary/artifact names.
7. Release build and tag creation are coupled in one large workflow and hard to recover.

## Final Audit Commands

1. `scripts/audit-workflows.sh .`
2. `scripts/audit-release-naming.sh .`
