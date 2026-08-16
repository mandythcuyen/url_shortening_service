#!/usr/bin/env bash
# Runs ON the Lightsail server, piped in over SSH by the deploy job in ci.yml.
# The image is already built and pushed by CI, so the server only pulls it.
set -euo pipefail

APP_DIR="${APP_DIR:-$HOME/url_shortening_service}"
IMAGE="${IMAGE:-ghcr.io/mandythcuyen/url_shortening_service}"
IMAGE_TAG="${IMAGE_TAG:-latest}"

cd "$APP_DIR"

# Refresh docker-compose.yml / Caddyfile without touching .env.production.
git fetch --prune origin main
git reset --hard origin/main

export WEB_IMAGE="${IMAGE}:${IMAGE_TAG}"
docker compose pull web
docker compose up -d --remove-orphans

# Wait for the new container to report healthy before declaring success.
for _ in $(seq 1 30); do
  status="$(docker compose ps --format '{{.Health}}' web)"
  [ "$status" = "healthy" ] && break
  sleep 5
done

if [ "${status:-}" != "healthy" ]; then
  echo "web container is not healthy (status: ${status:-unknown})" >&2
  docker compose logs --tail 50 web >&2
  exit 1
fi

docker image prune -f
echo "Deployed ${WEB_IMAGE}"
