#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage:
  scripts/openapi-bootstrap.sh <openapi.json> [output-dir]

Examples:
  scripts/openapi-bootstrap.sh ./openapi.json
  scripts/openapi-bootstrap.sh ./openapi.json ./docs/openapi
USAGE
}

spec="${1:-}"
out_dir="${2:-docs/openapi}"

if [[ -z "$spec" ]]; then
  usage
  exit 1
fi

if [[ ! -f "$spec" ]]; then
  echo "OpenAPI file not found: $spec" >&2
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq is required: https://jqlang.org/" >&2
  exit 1
fi

mkdir -p "$out_dir"

summary_md="$out_dir/openapi-summary.md"
ops_tsv="$out_dir/openapi-operations.tsv"
plan_md="$out_dir/openapi-command-plan.md"
test_md="$out_dir/openapi-test-matrix.md"

title=$(jq -r '.info.title // "unknown"' "$spec")
version=$(jq -r '.info.version // "unknown"' "$spec")

jq -r '
  def fallback_id($method; $path):
    (($method + "_" + $path)
      | ascii_downcase
      | gsub("[^a-z0-9]+"; "_")
      | gsub("^_+|_+$"; ""));

  (.paths // {})
  | to_entries[] as $p
  | ($p.value
      | to_entries[]
      | select(.key | test("^(get|post|put|patch|delete|options|head)$"))) as $op
  | [
      ($op.value.tags[0] // "default"),
      ($op.value.operationId // fallback_id($op.key; $p.key)),
      ($op.key | ascii_upcase),
      $p.key,
      ($op.value.summary // $op.value.description // ""),
      (if ($op.value.requestBody? != null) then "yes" else "no" end),
      (($op.value.responses // {})
        | keys_unsorted
        | map(select(test("^[0-9]{3}$")))
        | join(","))
    ]
  | @tsv
' "$spec" | LC_ALL=C sort > "$ops_tsv"

op_count=$(wc -l < "$ops_tsv" | tr -d ' ')

tag_counts=$(awk -F'\t' 'NF > 0 {count[$1]++} END {for (k in count) printf "%s\t%d\n", k, count[k]}' "$ops_tsv" | sort -k2,2nr -k1,1)

{
  echo "# OpenAPI Summary"
  echo
  printf -- '- Spec file: `%s`\n' "$spec"
  printf -- '- API title: `%s`\n' "$title"
  printf -- '- API version: `%s`\n' "$version"
  printf -- '- Total operations: `%s`\n' "$op_count"
  echo
  echo "## Operations by tag"
  echo
  if [[ -n "$tag_counts" ]]; then
    while IFS=$'\t' read -r tag count; do
      printf -- '- `%s`: %s\n' "$tag" "$count"
    done <<< "$tag_counts"
  else
    echo "- none"
  fi
} > "$summary_md"

{
  echo "# OpenAPI Command Plan"
  echo
  printf 'Generated from `%s`.\n' "$spec"
  echo
  echo "| Tag | Operation ID | Endpoint | Suggested CLI Command | Request Body | Success Codes |"
  echo "| --- | --- | --- | --- | --- | --- |"
  awk -F'\t' '
    {
      tag = $1
      op = $2
      method = $3
      path = $4
      req = $6
      codes = $7

      svc = tolower(tag)
      gsub(/[^a-z0-9]+/, "-", svc)
      gsub(/^-+|-+$/, "", svc)
      if (svc == "") svc = "default"

      op_cmd = op
      gsub(/_/, "-", op_cmd)

      cmd = svc " " op_cmd

      gsub(/\|/, "/", path)
      if (codes == "") codes = "200"

      printf "| `%s` | `%s` | `%s %s` | `%s` | %s | `%s` |\n", tag, op, method, path, cmd, req, codes
    }
  ' "$ops_tsv"
} > "$plan_md"

{
  echo "# OpenAPI Test Matrix"
  echo
  printf 'Generated from `%s`.\n' "$spec"
  echo
  echo "| Operation ID | Endpoint | Happy Path | Validation | Output Contract |"
  echo "| --- | --- | --- | --- | --- |"
  awk -F'\t' '
    {
      op = $2
      method = $3
      path = $4
      req = $6
      codes = $7

      split(codes, arr, ",")
      success = arr[1]
      if (success == "") success = "200"

      validation = (req == "yes") ? "request-body required/invalid cases" : "path/query validation cases"

      gsub(/\|/, "/", path)

      printf "| `%s` | `%s %s` | expect `%s` success response | %s | `--json` parseable, `--plain` stable, `--jq` JSON-only |\n", op, method, path, success, validation
    }
  ' "$ops_tsv"
} > "$test_md"

cat <<EOF
Generated OpenAPI bootstrap artifacts:
- $summary_md
- $ops_tsv
- $plan_md
- $test_md
EOF
