# Release Packaging Strategies

This reference prevents naming drift between workflows, docs, and release download commands.

## Strategy A: GoReleaser

Use when:
- You want one declarative config (`.goreleaser.yaml`) for build + archives + checksums + changelog.
- You need multi-platform packaging with low maintenance.

Naming source of truth:
- `.goreleaser.yaml` (archive naming and binary naming)
- `release-naming.env` (public docs and `gh` command hints)

Notes:
- Keep `TAG_PREFIX` aligned between workflow and goreleaser expectations.
- Keep `ARTIFACT_GLOB` aligned with produced archives.

## Strategy B: Manual Cross-Build + Upload

Use when:
- You need custom packaging behavior that is awkward in GoReleaser.
- You want direct shell-level control for artifact layout.

Naming source of truth:
- `release-naming.env`
- `release-on-tag-manual.yml` build/upload steps

Notes:
- Use one archive filename template for all matrix entries.
- Write checksums with a stable filename (`checksums.txt`).

## Required Naming Contract

Define once in `release-naming.env`:

- `CLI_NAME` (repo-facing logical name)
- `BINARY_NAME` (actual executable)
- `TAG_PREFIX` (for example `v` or `roam-cli-v`)
- `ARTIFACT_GLOB` (for example `roam-cli-*.tar.gz`)

## Safe `gh release download` Usage

Never hardcode names directly in docs.

Use:

```sh
scripts/print-release-download.sh <tag>
```

It prints a command template based on `release-naming.env`.

## Drift Signals

- Release succeeds but docs download command returns "no assets match".
- Tag is created with one prefix, publish workflow listens to another prefix.
- Binary name in archive differs from README installation examples.
