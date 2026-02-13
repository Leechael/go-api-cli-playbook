#!/usr/bin/env bash
set -euo pipefail

repo_dir="${1:-.}"
workflows_dir="$repo_dir/.github/workflows"
env_file="$repo_dir/release-naming.env"

if [[ ! -d "$workflows_dir" ]]; then
  echo "missing workflows dir: $workflows_dir" >&2
  exit 1
fi

if [[ ! -f "$env_file" ]]; then
  echo "missing release naming contract: $env_file" >&2
  exit 1
fi

# shellcheck disable=SC1090
source "$env_file"

for key in CLI_NAME BINARY_NAME TAG_PREFIX ARTIFACT_GLOB; do
  if [[ -z "${!key:-}" ]]; then
    echo "release-naming.env missing value: $key" >&2
    exit 1
  fi
done

echo "Auditing release naming in $repo_dir"

if rg -n "your-cli|your-cli-v" "$workflows_dir" >/dev/null; then
  echo "found unreplaced template placeholders in workflows" >&2
  rg -n "your-cli|your-cli-v" "$workflows_dir" >&2
  exit 1
fi

tag_glob="${TAG_PREFIX}*"
if ! rg -n --fixed-strings "$tag_glob" "$workflows_dir" >/dev/null; then
  echo "no workflow tag trigger matches TAG_PREFIX pattern: $tag_glob" >&2
  exit 1
fi

echo "release naming audit passed"
