#!/bin/bash
# Runs after the upstream migrations (50-laravel-automations.sh) and before
# supervisord opens the web port. Creates the instance owner from generated
# variables, so the public sign-up page never lets a stranger claim the instance.
# A failure stops the container (non-zero exit).
set -e
echo "[railway] checking the instance owner"
php /etc/entrypoint.d/lib/railway-bootstrap-owner.php
