# syntax=docker/dockerfile:1
# =============================================================================
# TrafficHacker (Dub fork) — self-contained image for ModelScope Docker studio.
# One container runs: Redis + SRH (Upstash REST proxy) + MariaDB + ps-http-sim
# (PlanetScale HTTP proxy) + a local Tinybird stub + the Next.js app on :7860.
# ModelScope constraints: serve on 0.0.0.0:7860; port 8080 is platform-reserved.
# =============================================================================

# ---- Stage 1: ps-http-sim (PlanetScale HTTP protocol simulator, Go) ---------
FROM golang:1.23-alpine AS pssim
# ModelScope builds on Alibaba infra: use Aliyun Alpine mirror + goproxy.cn so
# package/module fetches are fast and don't hit dl-cdn.alpinelinux.org timeouts.
RUN sed -i 's#dl-cdn.alpinelinux.org#mirrors.aliyun.com#g' /etc/apk/repositories && \
    apk add --no-cache git
ENV GOPROXY=https://goproxy.cn,direct
RUN CGO_ENABLED=0 GOBIN=/out go install github.com/mattrobenolt/ps-http-sim@latest

# ---- Stage 2: SRH (Upstash-compatible Redis REST proxy, Elixir/alpine) ------
FROM hiett/serverless-redis-http:latest AS srh

# ---- Stage 3: build the Next.js standalone bundle ---------------------------
FROM node:20-alpine AS builder
RUN sed -i 's#dl-cdn.alpinelinux.org#mirrors.aliyun.com#g' /etc/apk/repositories && \
    apk add --no-cache libc6-compat openssl git python3 make g++
RUN corepack enable && corepack prepare pnpm@9.15.9 --activate
# China-fast package sources for the ModelScope build (npm + Prisma engines).
ENV npm_config_registry=https://registry.npmmirror.com \
    PRISMA_ENGINES_MIRROR=https://registry.npmmirror.com/-/binary/prisma
WORKDIR /repo
COPY . .
RUN pnpm install --frozen-lockfile
RUN pnpm build:packages

# Build-time wiring for the studio host (client bundles inline NEXT_PUBLIC_*)
ARG APP_HOST=ljh0115-flus.ms.show
ENV DEPLOY_TARGET=modelscope \
    NEXT_PUBLIC_APP_DOMAIN=https://${APP_HOST} \
    NEXT_PUBLIC_APP_HOSTNAMES=${APP_HOST} \
    DATABASE_URL=mysql://root:@127.0.0.1:3306/planetscale \
    NEXTAUTH_URL=https://${APP_HOST} \
    NEXTAUTH_SECRET=build_time_placeholder \
    NODE_ENV=production

WORKDIR /repo/apps/web
RUN npx prisma generate --schema=./prisma/schema
RUN npx next build
# Emit the full DDL so the runtime image needs no Prisma CLI
RUN npx prisma migrate diff --from-empty \
      --to-schema-datamodel ./prisma/schema --script > /tmp/schema.sql

# ---- Stage 4: runtime --------------------------------------------------------
FROM node:20-alpine
RUN sed -i 's#dl-cdn.alpinelinux.org#mirrors.aliyun.com#g' /etc/apk/repositories && \
    apk add --no-cache mariadb mariadb-client redis \
      libstdc++ libgcc ncurses-libs openssl

COPY --from=pssim /out/ps-http-sim /usr/local/bin/ps-http-sim
COPY --from=srh /app /srh

WORKDIR /app
# Next standalone output preserves the monorepo layout (apps/web/server.js)
COPY --from=builder /repo/apps/web/.next/standalone ./
COPY --from=builder /repo/apps/web/.next/static ./apps/web/.next/static
COPY --from=builder /repo/apps/web/public ./apps/web/public
COPY --from=builder /tmp/schema.sql ./deploy/schema.sql
COPY deploy/modelscope/seed.sql.tpl deploy/modelscope/tinybird-stub.js deploy/modelscope/start.sh ./deploy/
RUN chmod +x /app/deploy/start.sh

EXPOSE 7860
CMD ["/app/deploy/start.sh"]
