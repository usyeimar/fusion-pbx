#!/usr/bin/env bash
# Start the FusionPBX stack.
#   ./scripts/start.sh          dev mode  → build, up, and follow the PBX logs
#   ./scripts/start.sh --prod   prod mode → build, up detached, print access info
set -euo pipefail
cd "$(dirname "$0")/.."

[[ -f .env ]] || { echo "❌ Copy .env.example to .env and configure it first."; exit 1; }
set -a; source .env; set +a

MODE="dev"
for arg in "$@"; do
  case "$arg" in
    prod|--prod|-d|--detach) MODE="prod" ;;
    dev|--dev)               MODE="dev" ;;
    *) echo "Unknown option: $arg (use --prod or --dev)"; exit 1 ;;
  esac
done

FREESWITCH_IMAGE="${FREESWITCH_IMAGE:-usyeimar/freeswitch:latest}"

# Build the FreeSWITCH base image first if it isn't present locally
if ! docker image inspect "$FREESWITCH_IMAGE" >/dev/null 2>&1; then
  echo "🧱 FreeSWITCH base image not found — building it (first time takes a while)..."
  ./scripts/build.sh base
fi

echo "🚀 Building and starting FusionPBX (mode: $MODE)..."
docker compose up -d --build

if [[ "$MODE" == "dev" ]]; then
  echo "📋 Following PBX logs (Ctrl+C to detach — containers keep running)..."
  docker compose logs -f
else
  docker compose ps
  echo "✅ FusionPBX is up. Web UI → https://<host>:8443  (HTTP :8080)"
fi
