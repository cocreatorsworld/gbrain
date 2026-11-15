#!/bin/sh
# deploy/railway/start.sh — container entrypoint for the Railway image.
# 1. first boot only: create the brain config against Postgres
# 2. every boot: apply pending migrations (non-fatal; the server reports state)
# 3. start the job supervisor in the background, then the HTTP MCP server
set -eu

export GBRAIN_HOME="${GBRAIN_HOME:-/data}"
DB_URL="${GBRAIN_DATABASE_URL:-${DATABASE_URL:-}}"
if [ -z "$DB_URL" ]; then
  echo ">>> GBRAIN_DATABASE_URL (or DATABASE_URL) is required." >&2
  exit 1
fi
PORT="${PORT:-8080}"
PUBLIC_URL="${GBRAIN_PUBLIC_URL:-}"
if [ -z "$PUBLIC_URL" ] && [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
  PUBLIC_URL="https://${RAILWAY_PUBLIC_DOMAIN}"
fi
if [ -z "${GBRAIN_ADMIN_BOOTSTRAP_TOKEN:-}" ]; then
  echo ">>> WARNING: GBRAIN_ADMIN_BOOTSTRAP_TOKEN is not set; the admin token changes on every restart." >&2
fi

mkdir -p "$GBRAIN_HOME"
cd "$GBRAIN_HOME"
echo ">>> gbrain $(gbrain --version 2>/dev/null || echo unknown) | home: $GBRAIN_HOME/.gbrain | public url: ${PUBLIC_URL:-<unset>}"

if [ ! -f "$GBRAIN_HOME/.gbrain/config.json" ]; then
  echo ">>> No config found; initializing the brain on Postgres..."
  set -- --url "$DB_URL" --non-interactive --skip-embed-check
  if [ -n "${GBRAIN_EMBEDDING_MODEL:-}" ]; then set -- "$@" --embedding-model "$GBRAIN_EMBEDDING_MODEL"; fi
  if [ -n "${GBRAIN_EMBEDDING_DIMENSIONS:-}" ]; then set -- "$@" --embedding-dimensions "$GBRAIN_EMBEDDING_DIMENSIONS"; fi
  gbrain init "$@"
fi

echo ">>> Applying migrations..."
gbrain apply-migrations --yes --no-autopilot-install \
  || echo ">>> apply-migrations exited non-zero; continuing. Check: gbrain doctor" >&2

echo ">>> Starting job supervisor..."
gbrain jobs supervisor --concurrency "${GBRAIN_WORKER_CONCURRENCY:-2}" &

echo ">>> Starting HTTP server on :$PORT"
set -- serve --http --port "$PORT" --bind 0.0.0.0 --fail-fast --suppress-bootstrap-token
if [ -n "$PUBLIC_URL" ]; then set -- "$@" --public-url "$PUBLIC_URL"; fi
exec gbrain "$@"
