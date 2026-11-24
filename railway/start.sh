#!/bin/bash
# Railway start script for Shoutrrr (runs as root, PID 1).
set -euo pipefail

APP=/var/www/html
STORAGE="$APP/storage"
export PORT="${PORT:-8080}"

# ---- Resources from the cgroup (Railway shows the host's CPUs, not the limit) ----
cpus=1
if [ -r /sys/fs/cgroup/cpu.max ]; then
    read -r quota period < /sys/fs/cgroup/cpu.max || true
    if [ "${quota:-max}" != "max" ] && [ -n "${period:-}" ] && [ "$period" -gt 0 ]; then
        cpus=$(( (quota + period - 1) / period ))
    else
        cpus=$(nproc 2>/dev/null || echo 2)
    fi
fi
[ "$cpus" -lt 1 ] && cpus=1
[ "$cpus" -gt 8 ] && cpus=8
mem_mb=2048
if [ -r /sys/fs/cgroup/memory.max ]; then
    m=$(cat /sys/fs/cgroup/memory.max)
    [ "$m" != "max" ] && mem_mb=$(( m / 1048576 ))
fi
export GOMAXPROCS="${GOMAXPROCS:-$cpus}"
export SHOUTRRR_FFMPEG_THREADS="${SHOUTRRR_FFMPEG_THREADS:-$cpus}"

# Octane (FrankenPHP) workers: "auto" means 2 per host CPU (64 on Railway), so
# size them from the service's own CPU and memory limits instead.
if [ -z "${OCTANE_WORKERS:-}" ]; then
    w=$(( cpus * 2 ))
    by_mem=$(( (mem_mb - 250) / 100 ))
    [ "$by_mem" -lt "$w" ] && w=$by_mem
    [ "$w" -lt 1 ] && w=1
    export OCTANE_WORKERS=$w
fi
# PHP memory limit (the image bakes 512M): below 1 GB of RAM use 256M.
if [ -n "${SHOUTRRR_PHP_MEMORY_LIMIT:-}" ]; then
    export PHP_MEMORY_LIMIT="$SHOUTRRR_PHP_MEMORY_LIMIT"
elif [ "$mem_mb" -lt 1000 ]; then
    export PHP_MEMORY_LIMIT=256M
    export PHP_OPCACHE_MEMORY_CONSUMPTION=128
fi
echo "[railway] cpus=$cpus mem=${mem_mb}MB octane_workers=$OCTANE_WORKERS php_memory_limit=$PHP_MEMORY_LIMIT"

# ---- APP_URL: ignore an empty or half-resolved value ----
case "${APP_URL:-}" in
    http://?*|https://?*) ;;
    *)
        if [ -n "${RAILWAY_PUBLIC_DOMAIN:-}" ]; then
            export APP_URL="https://$RAILWAY_PUBLIC_DOMAIN"
        else
            export APP_URL="http://localhost:$PORT"
        fi
        echo "[railway] APP_URL was empty or invalid; using $APP_URL"
        ;;
esac
APP_URL="${APP_URL%/}"; export APP_URL

# ---- APP_KEY: Laravel needs 32 raw bytes or base64:... ----
if [ -z "${APP_KEY:-}" ]; then
    echo "[railway] APP_KEY is not set; refusing to start" >&2
    exit 1
fi
case "$APP_KEY" in
    base64:*) ;;
    *)
        if [ "${#APP_KEY}" -ne 32 ]; then
            APP_KEY="base64:$(php -r 'echo base64_encode(hash("sha256", getenv("APP_KEY"), true));')"
            export APP_KEY
        fi
        ;;
esac

# ---- Volume: Railway mounts it root-owned; hand it to www-data ----
mkdir -p "$STORAGE/database" "$STORAGE/app/public" "$STORAGE/app/private" \
         "$STORAGE/framework/cache/data" "$STORAGE/framework/sessions" \
         "$STORAGE/framework/views" "$STORAGE/logs"
find "$STORAGE" \( ! -user www-data -o ! -group www-data \) -exec chown www-data:www-data {} + 2>/dev/null || true

# ---- Run the upstream entrypoint + supervisord as www-data ----
child=0
stopping=0
on_term() {
    stopping=1
    [ "$child" -gt 0 ] && kill -TERM "$child" 2>/dev/null || true
}
trap on_term TERM INT

setpriv --reuid=www-data --regid=www-data --init-groups \
    env HOME=/var/www \
    docker-php-serversideup-entrypoint supervisord -c /etc/supervisor/railway.conf &
child=$!

set +e
while kill -0 "$child" 2>/dev/null; do
    wait "$child"
done
wait "$child" 2>/dev/null
code=$?
set -e

if [ "$stopping" -eq 1 ]; then
    echo "[railway] stopped on request"
    exit 0
fi
echo "[railway] Shoutrrr stopped unexpectedly (exit $code); exiting non-zero so Railway restarts it" >&2
exit 1
