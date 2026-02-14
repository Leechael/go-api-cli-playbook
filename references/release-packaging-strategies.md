# Release Packaging Strategies

This reference keeps release behavior consistent even when projects choose different packaging tools.

## Mandatory Outcomes (Both Strategies)

1. Release tag format is `vX.Y.Z`.
2. GitHub Release is created for each tag.
3. Artifacts include darwin/linux x amd64/arm64 builds.
4. Archive contains a consistent binary name (`BINARY_NAME`).
5. `dist/CHANGELOG.md` is generated and used as release body.
6. Download command examples use `ARTIFACT_GLOB`.

## Strategy A: Canonical Manual Packaging (Template Default)

Use `release-on-tag.yml` from templates.

- Pros:
  - fully explicit artifact naming and changelog generation
  - no extra config file required
- Contract:
  - read `BINARY_NAME`, `TAG_PREFIX`, `ARTIFACT_GLOB`, `BUILD_TARGET` from `release-naming.env`

## Strategy B: GoReleaser

Use when a repo already has mature `.goreleaser.yml`.

- Required alignment:
  - `.goreleaser.yml` archive names must match `ARTIFACT_GLOB`
  - binary names in archives must match `BINARY_NAME`
  - release notes/changelog must be enabled and equivalent to `dist/CHANGELOG.md` behavior
  - workflow still needs explicit dispatch path and `v*` tag trigger

## Required Naming Contract

Define once in `release-naming.env`:

- `CLI_NAME`
- `BINARY_NAME`
- `TAG_PREFIX` (default: `v`)
- `ARTIFACT_GLOB` (for example: `mycli-*.tar.gz`)
- `BUILD_TARGET` (for example: `./cmd/mycli`)

## Safe Download Command

Never hardcode download pattern in docs.

Use:

```sh
scripts/print-release-download.sh <tag>
```
