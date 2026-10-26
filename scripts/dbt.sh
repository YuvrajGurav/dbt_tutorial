
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

echo "Step 1: Checking dbt and Databricks connection..."

docker compose run --rm \
  -e DATABRICKS_TOKEN \
  dbt debug

echo
echo "Step 2: Starting your dbt environment..."

exec docker compose run --rm -it \
  --entrypoint /bin/bash \
  -e DATABRICKS_TOKEN \
  -e PS1='(dbt) \u@\h:\w\$ ' \
  dbt --norc -i
