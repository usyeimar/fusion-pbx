#!/usr/bin/env bash
# Build images.
#   ./scripts/build.sh          build FreeSWITCH base (if missing) + FusionPBX
#   ./scripts/build.sh base     build only the FreeSWITCH base image
#   ./scripts/build.sh app      build only the FusionPBX image
#   PLATFORM=linux/amd64,linux/arm/v7 ./scripts/build.sh buildx   multi-arch push
set -euo pipefail
cd "$(dirname "$0")/.."

[[ -f .env ]] && { set -a; source .env; set +a; }
FREESWITCH_IMAGE="${FREESWITCH_IMAGE:-usyeimar/freeswitch:latest}"
IMAGE_NAME="${IMAGE_NAME:-usyeimar/fusionpbx:latest}"

build_base() {
  echo "🧱 Building FreeSWITCH base image ($FREESWITCH_IMAGE)..."
  docker build -t "$FREESWITCH_IMAGE" -f freeswitch/Dockerfile .
}
build_app() {
  echo "📦 Building FusionPBX image ($IMAGE_NAME)..."
  docker compose build
}

case "${1:-all}" in
  base)  build_base ;;
  app)   build_app ;;
  all)   docker image inspect "$FREESWITCH_IMAGE" >/dev/null 2>&1 || build_base; build_app ;;
  buildx)
    PLATFORM="${PLATFORM:-linux/amd64}"
    echo "🌍 Multi-arch buildx ($PLATFORM) → pushing $IMAGE_NAME ..."
    docker buildx build --platform "$PLATFORM" --push -t "$IMAGE_NAME" .
    ;;
  *) echo "Usage: ./scripts/build.sh [base|app|all|buildx]"; exit 1 ;;
esac
echo "✅ Done"
