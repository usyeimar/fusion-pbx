#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

echo "⏹️  Stopping FusionPBX..."
docker compose down
echo "✅ Stopped"
