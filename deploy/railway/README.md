# Deploy gbrain on Railway

Runs this checkout as a hosted brain: `gbrain serve --http` (MCP + admin
dashboard) plus the background job supervisor, on a Postgres + pgvector
database.

**Say to your agent:** *"Deploy my gbrain fork to Railway"* — *"Upgrade my hosted brain on Railway"*

## Service settings

| Setting | Value |
|---|---|
| Source | your gbrain repository and branch |
| Root Directory | empty (the build needs the whole repository) |
| Variable `RAILWAY_DOCKERFILE_PATH` | `deploy/railway/Dockerfile` |
| Healthcheck path | `/health` |
| Volume | mounted at `/data` (holds `~/.gbrain` config and content) |

## Variables

| Variable | Required | Purpose |
|---|---|---|
| `GBRAIN_DATABASE_URL` (or `DATABASE_URL`) | yes | Postgres connection string, e.g. `${{Postgres.DATABASE_URL}}` |
| `GBRAIN_ADMIN_BOOTSTRAP_TOKEN` | yes | Owner credential for `/admin`; keep it in Railway variables only |
| `GBRAIN_PUBLIC_URL` | recommended | The URL clients use, e.g. `https://brain.example.com` (OAuth issuer). Defaults to the Railway domain |
| `GBRAIN_HTTP_TRUST_PROXY` | recommended | `1` behind Railway's proxy |
| `OPENAI_API_KEY` or `VOYAGE_API_KEY` | for semantic search | Embedding provider key |
| `GBRAIN_EMBEDDING_MODEL`, `GBRAIN_EMBEDDING_DIMENSIONS` | optional | e.g. `openai:text-embedding-3-small` and `1024` |
| `GBRAIN_WORKER_CONCURRENCY` | optional | Background worker concurrency (default 2) |

## What happens at boot

1. First boot only (no `/data/.gbrain/config.json`): `gbrain init --url …`.
2. Every boot: `gbrain apply-migrations --yes --no-autopilot-install`
   (non-fatal; run `gbrain doctor` if it reports a problem).
3. `gbrain jobs supervisor` starts in the background, then
   `gbrain serve --http --bind 0.0.0.0 --public-url …` takes the foreground.

To upgrade, update the branch Railway deploys from and redeploy. Keep a
Postgres backup before upgrading a brain that holds real data.
