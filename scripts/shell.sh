#!/usr/bin/env bash
# Open a shell inside the fusionpbx container.
cd "$(dirname "$0")/.."
docker compose exec fusionpbx bash || docker compose exec fusionpbx sh
