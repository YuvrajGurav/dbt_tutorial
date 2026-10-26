
#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$(readlink -f "$0")")/.."

if ! command -v databricks >/dev/null 2>&1; then
  echo "Error: Databricks CLI is not installed."
  exit 1
fi

echo "Refreshing Databricks OAuth credentials..."

token_json="$(databricks auth token dbt-dev)"

export DATABRICKS_TOKEN="$(
  printf '%s' "$token_json" |
    python3 -c 'import json,sys; print(json.load(sys.stdin)["access_token"])'
)"

unset token_json

if [[ -z "$DATABRICKS_TOKEN" ]]; then
  echo "Error: Could not obtain an OAuth access token."
  exit 1
fi

echo "Running dbt debug..."

exec docker compose run --rm \
  -e DATABRICKS_TOKEN \
  dbt debug
