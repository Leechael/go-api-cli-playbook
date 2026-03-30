#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/init-project-files.sh [--force] <target-repo-dir>

Copies Makefile, .gitignore, README.md, and prek.toml templates to the target repo.

Examples:
  scripts/init-project-files.sh /path/to/repo
  scripts/init-project-files.sh --force /path/to/repo
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
template_dir="$script_dir/../assets/templates"

files=("Makefile" ".gitignore" "README.md" "prek.toml")
copied=()

for f in "${files[@]}"; do
  src="$template_dir/$f"
  dest="$target/$f"

  if [[ ! -f "$src" ]]; then
    echo "template not found: $src" >&2
    continue
  fi

  if [[ -f "$dest" && "$force" != "true" ]]; then
    echo "skipping (already exists): $dest" >&2
    continue
  fi

  cp "$src" "$dest"
  copied+=("$dest")
done

if [[ ${#copied[@]} -eq 0 ]]; then
  echo "No files copied. Use --force to overwrite existing files." >&2
  exit 0
fi

echo "Copied templates:"
for f in "${copied[@]}"; do
  echo "  $f"
done

cat <<EOF

Next steps:
  edit Makefile: set BINARY_NAME and CMD to match release-naming.env
  edit README.md: replace your-cli, OWNER/REPO, YOUR_SERVICE_NAME
  edit .gitignore: add any project-specific patterns
  run prek validate-config
  run prek install --install-hooks
EOF
