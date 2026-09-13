#!/usr/bin/env bash
###############################################################################
# custom_startup.sh  (DinD)
#
# Matches Kasm's own reference DinD image (kasmtech/workspaces-images,
# src/ubuntu/install/dind/custom_startup.sh): supervisord - which manages the
# nested Docker daemon, see dockerd.conf - is started only once the desktop
# session is confirmed ready via Kasm's own filter_ready/desktop_ready gates,
# and is respawned automatically if it ever dies.
#
# Kasm executes this at session start. DISABLE_CUSTOM_STARTUP=true skips the
# watchdog loop entirely (e.g. while debugging a stuck session).
###############################################################################
set -e

log() { echo "[dind-startup] $*"; }

if [ -n "${DISABLE_CUSTOM_STARTUP:-}" ]; then
    log "DISABLE_CUSTOM_STARTUP set; not starting supervisord."
    exit 0
fi

log "Entering supervisord watchdog loop..."
while true; do
    if ! pgrep -x supervisord >/dev/null 2>&1; then
        /usr/bin/filter_ready
        /usr/bin/desktop_ready
        log "Desktop ready; starting supervisord (manages dockerd - see /etc/supervisor/conf.d/dockerd.conf)"
        set +e
        sudo /usr/bin/supervisord -n &
        set -e
    fi
    sleep 1
done
