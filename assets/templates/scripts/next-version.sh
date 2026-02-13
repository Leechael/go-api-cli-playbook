#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./scripts/next-version.sh <tag-prefix> <patch|minor|major> [alpha|beta|rc]
# Example:
#   ./scripts/next-version.sh roam-cli-v patch beta

TAG_PREFIX="${1:-}"
BUMP="${2:-patch}"
PRE="${3:-}"

if [[ -z "$TAG_PREFIX" ]]; then
  echo "tag prefix is required" >&2
  exit 1
fi

case "$BUMP" in
  patch|minor|major) ;;
  *)
    echo "invalid bump: $BUMP" >&2
    exit 1
    ;;
esac

if [[ -n "$PRE" ]]; then
  case "$PRE" in
    alpha|beta|rc) ;;
    *)
      echo "invalid prerelease: $PRE" >&2
      exit 1
      ;;
  esac
fi

latest_tag=$(git tag -l "${TAG_PREFIX}*" --sort=-version:refname | head -n1)
if [[ -z "$latest_tag" ]]; then
  base_version="0.0.0"
else
  base_version="${latest_tag#${TAG_PREFIX}}"
  base_version="${base_version%%-*}"
fi

IFS='.' read -r major minor patch <<< "$base_version"
major=${major:-0}
minor=${minor:-0}
patch=${patch:-0}

case "$BUMP" in
  patch)
    patch=$((patch + 1))
    ;;
  minor)
    minor=$((minor + 1))
    patch=0
    ;;
  major)
    major=$((major + 1))
    minor=0
    patch=0
    ;;
esac

version="${major}.${minor}.${patch}"

if [[ -n "$PRE" ]]; then
  max_n=0
  while IFS= read -r tag; do
    suffix="${tag#${TAG_PREFIX}${version}-${PRE}.}"
    if [[ "$suffix" =~ ^[0-9]+$ ]] && (( suffix > max_n )); then
      max_n=$suffix
    fi
  done < <(git tag -l "${TAG_PREFIX}${version}-${PRE}.*")
  version="${version}-${PRE}.$((max_n + 1))"
fi

echo "$version"
