# Prek Pre-Commit Setup

This reference defines the pre-test gate using `prek`.

## Why

- Catch style and fast sanity failures before test runs.
- Keep local checks and CI checks aligned.
- Reduce workflow churn caused by late formatting/lint failures.

## Source

- Quickstart: https://prek.j178.dev/guide/quickstart
- Installation: https://prek.j178.dev/guide/installation
- FAQ (`--install-hooks`): https://prek.j178.dev/guide/faq

## Bootstrap Steps

1. Install `prek` using one of the official installation methods.
2. Copy `assets/templates/prek.toml` to your repo root as `prek.toml`.
3. Validate config:
   - `prek validate-config`
4. Install hooks:
   - `prek install --install-hooks`
5. Run all checks once:
   - `prek run --all-files`

## Required Order Before Testing

1. `prek run --all-files`
2. `go test ...`

## CI Behavior

- The CI template runs `prek validate-config` and `prek run --all-files` before unit tests when a pre-commit config file exists.
- If config exists but `prek` is missing, CI fails fast.
