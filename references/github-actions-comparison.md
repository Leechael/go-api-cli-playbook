# GitHub Actions Comparison Notes

This reference captures failure patterns seen in `customerio-skills` and `roamresearch-skills` and the standardized fixes in this playbook.

## Observed Failures

1. Tag created but release missing:
- Root cause: release command workflow created tag but did not reliably dispatch `release-on-tag.yml` (wrong workflow id or no dispatch).

2. Comment trigger inconsistency:
- Root cause: parser regex was case-insensitive but job-level gate was case-sensitive, so some variants like `!Release patch` were skipped.

3. Packaging/name drift:
- Root cause: artifact naming, tag prefix, and docs examples were maintained in different places.

4. Inconsistent binary names inside archives:
- Root cause: packaging scripts used hardcoded output names across projects.

## Standardized Pattern

1. `release-command.yml`:
- supports `issue_comment`, `pull_request_review_comment`, and `workflow_dispatch`
- parses only `!release <patch|minor|major>` case-insensitively
- creates tag from `release-naming.env` + `scripts/next-version.sh`
- dispatches `release-on-tag.yml` explicitly

2. `release-on-tag.yml`:
- builds darwin/linux x amd64/arm64 archives
- archive names and binary names come from naming contract
- generates `dist/CHANGELOG.md`
- publishes GitHub release with changelog as body

3. Naming contract:
- `release-naming.env` is the single source of truth:
  - `CLI_NAME`
  - `BINARY_NAME`
  - `TAG_PREFIX` (default `v`)
  - `ARTIFACT_GLOB`
  - `BUILD_TARGET`

4. Drift prevention:
- `scripts/audit-workflows.sh`
- `scripts/audit-release-naming.sh`
