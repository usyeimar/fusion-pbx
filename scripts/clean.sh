#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

read -r -p "⚠️  This removes containers, volumes and network (the database will be lost). Continue? (yes/no): " confirm
[[ "$confirm" == "yes" ]] || { echo "Cancelled."; exit 0; }

echo "🗑️  Cleaning up..."
docker compose down -v --remove-orphans
echo "✅ Clean"
