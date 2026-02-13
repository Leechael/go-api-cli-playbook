# go-api-cli-playbook

A reusable engineering playbook for building Go CLI tools on top of APIs. It provides opinionated defaults for CLI output contracts, layered testing (unit / BDD / integration), GitHub Actions CI/release workflows, and release naming consistency.

## Problem

Go API-to-CLI projects tend to accumulate the same issues across repos:

- GitHub Actions workflows drift apart over time
- CLI output breaks scripts and automation silently
- Release artifact names get out of sync with docs and download commands
- Pre-commit and test strategies are set up inconsistently

This playbook captures those lessons into templates, scripts, and audit tools so they only need to be solved once.

It also includes an OpenAPI-first path so a new CLI can be planned and tested from only `openapi.json`.

## What's Included

```
assets/templates/       # Copy-ready templates
  prek.toml             #   Pre-commit gate config
  release-naming.env    #   Single source of truth for naming
  scripts/
    next-version.sh     #   Tag-based version calculation

references/             # Decision guides and checklists
  github-actions-comparison.md
  github-actions-adoption-checklist.md
  openapi-first-delivery.md
  release-packaging-strategies.md
  prek-precommit.md

scripts/                # Bootstrap and audit tools
  init-prek.sh          #   Set up prek in a target repo
  init-release-naming.sh#   Bootstrap release-naming.env
  openapi-bootstrap.sh  #   Build command/test plan from openapi.json
  print-release-download.sh  # Generate correct download commands
  audit-workflows.sh    #   Detect workflow config drift
  audit-release-naming.sh   # Detect naming contract drift

SKILL.md                # Claude Code skill definition
```

## Quick Start

Apply the playbook to a target Go CLI repository:

```bash
# 1. Bootstrap the release naming contract
./scripts/init-release-naming.sh /path/to/your-repo

# 2. If starting from API docs only, generate plan artifacts
./scripts/openapi-bootstrap.sh /path/to/openapi.json /path/to/your-repo/docs/openapi

# 3. Set up pre-commit gate
./scripts/init-prek.sh /path/to/your-repo

# 4. Copy workflow templates into your repo and replace placeholders

# 5. Audit for drift
./scripts/audit-workflows.sh /path/to/your-repo
./scripts/audit-release-naming.sh /path/to/your-repo

# 6. Validate locally
prek run --all-files
go test ./...
```

## Key Contracts

**CLI Output** — Parseable output modes (`--json`, `--plain`) are mandatory. Human hints go to stderr. Exit codes must be stable and script-safe.

**Testing** — Run `prek run --all-files` before tests. Unit tests via `go test ./...`. BDD paths must be explicit. Integration tests are opt-in (tagged and credential-gated).

**CI/CD** — CI runs formatting, vet/lint, tests, and build. A separate release-command workflow parses, validates, and creates tags. A tag-triggered workflow builds artifacts and publishes the release.

**Release Naming** — `CLI_NAME`, `BINARY_NAME`, `TAG_PREFIX`, and `ARTIFACT_GLOB` live in `release-naming.env` as the single source of truth. No hardcoding elsewhere.

## As a Claude Code Skill

This repo doubles as a [Claude Code skill](https://docs.anthropic.com/en/docs/claude-code/skills). Add it to your workspace and Claude will follow the playbook when building Go CLI projects.

## License

[MIT](LICENSE)
