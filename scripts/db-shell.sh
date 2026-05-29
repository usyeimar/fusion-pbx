#!/usr/bin/env bash
# Open a psql shell against the PostgreSQL container.
cd "$(dirname "$0")/.."
[[ -f .env ]] && { set -a; source .env; set +a; }
docker compose exec postgres psql -U "${DB_USER:-fusionpbx}" -d "${DB_NAME:-fusionpbx}"
