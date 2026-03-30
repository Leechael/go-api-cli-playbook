#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/init-prek.sh [--force] <target-repo-dir>

Examples:
  scripts/init-prek.sh /path/to/repo
  scripts/init-prek.sh --force /path/to/repo
USAGE
}

force="false"
if [[ "${1:-}" == "--force" ]]; then
  force="true"
  shift
fi

target="${1:-}"
if [[ -z "$target" ]]; then
  usage
  exit 1
fi

if [[ ! -d "$target" ]]; then
  echo "target repo dir does not exist: $target" >&2
  exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
template="$script_dir/../assets/templates/prek.toml"
dest="$target/prek.toml"

if [[ -f "$dest" && "$force" != "true" ]]; then
  cat <<EOF
prek.toml already exists, skipping copy:
  $dest

Next steps:
  cd $target
  prek validate-config
  prek install --install-hooks
  prek run --all-files

Use --force to overwrite existing prek.toml.
EOF
  exit 0
fi

cp "$template" "$dest"

cat <<EOF
Copied template:
  $dest

Next steps:
  cd $target
  prek validate-config
  prek install --install-hooks
  prek run --all-files
EOF
