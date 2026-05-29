#!/usr/bin/env bash
# Tail logs. Optional arg = service name (fusionpbx | postgres). No arg = all.
cd "$(dirname "$0")/.."

if [[ -n "${1:-}" ]]; then
  docker compose logs -f "$1"
else
  docker compose logs -f
fi
