# OpenAPI-First Delivery

Use this flow when API docs are your only implementation input.

## Input

- One OpenAPI JSON file (`openapi.json`).

## Command

```sh
scripts/openapi-bootstrap.sh openapi.json docs/openapi
```

## Outputs

The script generates:

- `docs/openapi/openapi-summary.md`
- `docs/openapi/openapi-operations.tsv`
- `docs/openapi/openapi-command-plan.md`
- `docs/openapi/openapi-test-matrix.md`

## How To Use The Outputs

1. `openapi-operations.tsv`
- Canonical machine-readable inventory of method/path/operationId/tag.
- Use this as the source for command coverage tracking.

2. `openapi-command-plan.md`
- Suggested CLI command mapping per operation.
- Use operation IDs as canonical intent keys.

3. `openapi-test-matrix.md`
- Baseline test expectations for each operation.
- Add your service-specific edge cases after baseline is in place.

## Required Rules

1. No operation should be silently dropped.
- If operation is intentionally unsupported, mark it in the plan.

2. Output contract applies to every generated command.
- `--json` parseable mode
- `--plain` stable plain mode
- `--jq` allowed only in JSON mode

3. Release naming is still mandatory.
- OpenAPI-first affects command generation, not release policy.
- Keep `release-naming.env` as the naming source of truth.

## Notes

- If `operationId` is missing, the bootstrap script creates a deterministic fallback id.
- If your spec uses YAML, convert to JSON first.
