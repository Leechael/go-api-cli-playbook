# your-cli

`your-cli` is a command-line tool for working with YOUR_SERVICE_NAME.

---

## Install

### Option A: Download from GitHub Releases

```bash
gh release list -R OWNER/REPO
TAG="vX.Y.Z"
gh release download "$TAG" -R OWNER/REPO --pattern "your-cli-*.tar.gz"
```

Extract the archive for your platform and place `your-cli` in your `PATH`.

### Option B: Build from source

```bash
git clone git@github.com:OWNER/REPO.git
cd REPO
make build
```

---

## Required configuration

Set credentials via environment variable:

```bash
export YOUR_SERVICE_API_TOKEN="<token>"
```

Validate setup before use:

```bash
your-cli status
your-cli status --json
```

---

## Commands

<!-- Replace with actual command tree -->

- `status` — check credentials and API connectivity
- `resource list` (alias: `ls`) — list resources with filters
- `resource get <id>` — get a single resource

### Output modes

- `--json` for machine-readable JSON output.
- `--plain` for tab-separated stable output.
- `--jq` with `--json` for filtered JSON output.
- Human hints are printed to stderr, data to stdout.

---

## Usage examples

```bash
# status
your-cli status
your-cli status --json

# list resources
your-cli resource list --json
your-cli resource list --page-size 10 --json
your-cli resource get 123 --plain
```

---

## Development

```bash
make build        # build to bin/your-cli
make test         # unit tests
make bdd-test     # BDD tests
make ci           # full CI check (fmt + vet + test + build)
make fmt          # auto-format Go source
make cross-build  # build all platforms
```

---

## Recommended secret handling

Use 1Password CLI to inject credentials at runtime:

```bash
op run --env-file=.env -- your-cli status
op run --env-file=.env -- your-cli resource list --json
```
