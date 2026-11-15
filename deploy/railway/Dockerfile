# deploy/railway/Dockerfile — run this checkout of gbrain as a hosted brain on Railway.
#
# Build context is the REPO ROOT (set the Railway service variable
# RAILWAY_DOCKERFILE_PATH=deploy/railway/Dockerfile and leave Root Directory empty).
# The image runs `gbrain serve --http` plus the background job supervisor; see
# deploy/railway/README.md for the variables it reads.
ARG BUN_IMAGE=oven/bun:1.4.4
FROM ${BUN_IMAGE}

RUN apt-get update \
    && apt-get install -y --no-install-recommends git ca-certificates curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Dependency layer first so code-only changes rebuild fast.
COPY package.json bun.lock bunfig.toml ./
COPY patches/ patches/
RUN GBRAIN_NO_AUTOPILOT_INSTALL=1 bun install --frozen-lockfile --production

COPY . .

# `gbrain` on PATH, always run from this checkout.
RUN printf '#!/bin/sh\nexec bun /app/src/cli.ts "$@"\n' > /usr/local/bin/gbrain \
    && chmod +x /usr/local/bin/gbrain /app/deploy/railway/start.sh \
    && gbrain --version

ENV GBRAIN_HOME=/data \
    GBRAIN_NO_AUTOPILOT_INSTALL=1 \
    PORT=8080
EXPOSE 8080

CMD ["/app/deploy/railway/start.sh"]
