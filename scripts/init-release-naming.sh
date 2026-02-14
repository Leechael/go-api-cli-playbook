#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/init-release-naming.sh [--force] <target-repo-dir>

Examples:
  scripts/init-release-naming.sh /path/to/repo
  scripts/init-release-naming.sh --force /path/to/repo
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
template="$script_dir/../assets/templates/release-naming.env"
dest="$target/release-naming.env"

if [[ -f "$dest" && "$force" != "true" ]]; then
  echo "release-naming.env already exists: $dest" >&2
  echo "Use --force to overwrite." >&2
  exit 1
fi

cp "$template" "$dest"

cat <<EOF
Copied template:
  $dest

Next steps:
  edit CLI_NAME/BINARY_NAME/ARTIFACT_GLOB/BUILD_TARGET in $dest
  keep TAG_PREFIX=v unless you have a strict migration reason
  ensure workflow tag patterns and artifact names match this file
EOF
