#!/bin/sh
# Entrypoint for the self-contained ModelScope (Docker studio) deploy.
# Boots, in order: Redis -> SRH (Upstash REST proxy) -> MariaDB (+schema/seed)
# -> ps-http-sim (PlanetScale HTTP proxy) -> Tinybird stub -> Next.js on 7860.
# NOTE: port 8080 is reserved by the ModelScope platform inside the container.
set -e

echo "[start] TrafficHacker self-contained boot"

# ---------------------------------------------------------------------------
# Runtime configuration (all overridable via studio environment variables)
# ---------------------------------------------------------------------------
APP_HOST="${APP_HOST:-ljh0115-flus.ms.show}"
export NEXTAUTH_URL="${NEXTAUTH_URL:-https://$APP_HOST}"
export NEXTAUTH_SECRET="${NEXTAUTH_SECRET:-$(head -c 32 /dev/urandom | base64 | tr -d '\n')}"
export ENCRYPTION_KEY="${ENCRYPTION_KEY:-$(head -c 32 /dev/urandom | base64 | tr -d '\n')}"
export DATABASE_URL="mysql://root:@127.0.0.1:3306/planetscale"
export PLANETSCALE_DATABASE_URL="http://root:unused@127.0.0.1:3900/planetscale"
export UPSTASH_REDIS_REST_URL="http://127.0.0.1:8079"
export UPSTASH_REDIS_REST_TOKEN="local_srh_token"
export QSTASH_URL="http://127.0.0.1:9"   # dead port: publishes fail silently (soft dependency)
export QSTASH_TOKEN="unused"
export TINYBIRD_API_URL="http://127.0.0.1:7423"
export TINYBIRD_API_KEY="stub"
export DEPLOY_TARGET="modelscope"
export NODE_ENV="production"

# ---------------------------------------------------------------------------
# 1. Redis (local, ephemeral)
# ---------------------------------------------------------------------------
redis-server --port 6379 --bind 127.0.0.1 --save '' --appendonly no --daemonize yes
echo "[start] redis up"

# ---------------------------------------------------------------------------
# 2. SRH: Upstash REST-compatible proxy in front of local Redis
#    (default SRH port is 8080 which ModelScope reserves -> use 8079)
# ---------------------------------------------------------------------------
SRH_BIN="$(ls /srh/bin/* 2>/dev/null | head -1)"
env SRH_MODE=env \
    SRH_TOKEN=local_srh_token \
    SRH_CONNECTION_STRING="redis://127.0.0.1:6379" \
    SRH_PORT=8079 \
    HOME=/tmp \
    "$SRH_BIN" start &
echo "[start] srh starting ($SRH_BIN)"

# ---------------------------------------------------------------------------
# 3. MariaDB (root/no password over local TCP, like Dub's local dev compose)
# ---------------------------------------------------------------------------
mkdir -p /run/mysqld /data/mysql
chown -R mysql:mysql /run/mysqld /data/mysql
FRESH_DB=0
if [ ! -d /data/mysql/mysql ]; then
  FRESH_DB=1
  mariadb-install-db --user=mysql --datadir=/data/mysql \
    --auth-root-authentication-method=normal --skip-test-db >/dev/null 2>&1
fi
mariadbd --user=mysql --datadir=/data/mysql --bind-address=127.0.0.1 \
  --port=3306 --skip-name-resolve --max_connections=500 &
i=0
until mariadb-admin -h 127.0.0.1 -u root ping --silent 2>/dev/null; do
  i=$((i+1)); [ $i -gt 60 ] && echo "[start] FATAL: mariadb not up" && exit 1
  sleep 1
done
echo "[start] mariadb up"

if [ "$FRESH_DB" = "1" ]; then
  mariadb -h 127.0.0.1 -u root -e "CREATE DATABASE IF NOT EXISTS planetscale CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
  mariadb -h 127.0.0.1 -u root planetscale < /app/deploy/schema.sql
  sed "s/__APP_HOST__/$APP_HOST/g" /app/deploy/seed.sql.tpl | mariadb -h 127.0.0.1 -u root planetscale
  echo "[start] schema + demo seed applied (login: demo@traffic-hacker.com / Demo2026!)"
fi

# ---------------------------------------------------------------------------
# 4. ps-http-sim: PlanetScale HTTP protocol proxy for the @planetscale/database
#    driver used on the short-link hot path
# ---------------------------------------------------------------------------
ps-http-sim -mysql-no-pass -listen-port=3900 -mysql-addr=127.0.0.1 \
  -mysql-port=3306 -mysql-dbname=planetscale &
echo "[start] ps-http-sim up on :3900"

# ---------------------------------------------------------------------------
# 5. Tinybird stub (analytics soft dependency)
# ---------------------------------------------------------------------------
node /app/deploy/tinybird-stub.js &

# ---------------------------------------------------------------------------
# 6. Next.js standalone server on the ModelScope-mandated port
# ---------------------------------------------------------------------------
cd /app/apps/web
export PORT=7860 HOSTNAME=0.0.0.0
echo "[start] launching Next.js on 0.0.0.0:7860 (app host: $APP_HOST)"
exec node server.js
