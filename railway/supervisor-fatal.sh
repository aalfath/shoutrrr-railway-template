#!/bin/bash
# supervisord event listener: if any program enters FATAL (it could not be
# restarted), stop supervisord so the container exits and Railway restarts it.
printf 'READY\n'
while read -r header; do
    len=$(printf '%s\n' "$header" | sed -n 's/.*len:\([0-9]*\).*/\1/p')
    payload=""
    [ -n "$len" ] && [ "$len" -gt 0 ] && read -r -n "$len" payload
    echo "[railway] supervisord program entered FATAL: $payload" >&2
    kill -TERM "$PPID" 2>/dev/null
    printf 'RESULT 2\nOK'
    printf 'READY\n'
done
