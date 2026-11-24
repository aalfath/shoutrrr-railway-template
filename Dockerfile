# Shoutrrr for Railway: the official upstream image, pinned by version and digest,
# plus a small wrapper (start script, supervisord config, first-boot owner bootstrap).
FROM ghcr.io/coollabsio/shoutrrr:1.5.9@sha256:a5835ba9255d9ba17e2fbd98efd6c1ea5c83114df9b9ba07cb50fc05d090118d

USER root

COPY --chmod=755 railway/start.sh /usr/local/bin/railway-start
COPY --chmod=755 railway/supervisor-fatal.sh /usr/local/bin/supervisor-fatal
COPY --chmod=755 railway/ffmpeg.sh /usr/local/bin/ffmpeg
COPY --chmod=644 railway/supervisord.conf /etc/supervisor/railway.conf
COPY --chmod=755 railway/60-railway-owner.sh /etc/entrypoint.d/60-railway-owner.sh
COPY --chmod=644 railway/bootstrap-owner.php /etc/entrypoint.d/lib/railway-bootstrap-owner.php

# Fixed settings for a single-container install behind Railway's HTTPS proxy.
# Everything lives on the one Railway volume mounted at /var/www/html/storage
# (uploads, Passport keys and the SQLite database).
ENV APP_ENV=production \
    APP_DEBUG=false \
    APP_NAME=Shoutrrr \
    SELF_HOSTED=true \
    OCTANE_HTTPS=true \
    TRUSTED_PROXIES="100.64.0.0/10,152.233.0.0/16" \
    SESSION_SECURE_COOKIE=true \
    SOCIALITE_ENABLED=false \
    INSTANCE_REGISTRATIONS_ENABLED=false \
    DB_CONNECTION=sqlite \
    DB_DATABASE=/var/www/html/storage/database/shoutrrr.sqlite \
    CACHE_STORE=database \
    QUEUE_CONNECTION=database \
    SESSION_DRIVER=database \
    LOG_CHANNEL=stderr \
    LOG_LEVEL=info \
    SHOW_WELCOME_MESSAGE=false \
    QUEUE_WORKER_ENABLED=true \
    SCHEDULER_ENABLED=true \
    INERTIA_SSR_ENABLED=false \
    PORT=8080

EXPOSE 8080

# The start script runs as root only to fix the volume's ownership, then runs
# the upstream entrypoint (migrations, caches, owner bootstrap) and supervisord
# as www-data. It exits non-zero whenever supervisord stops on its own, so
# Railway's ON_FAILURE restart policy brings the service back.
ENTRYPOINT ["/usr/local/bin/railway-start"]
CMD []
