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
# Deliberately NOT `set -e`. This is an infinite watchdog loop that Kasm's own
# session bring-up depends on; if it ever exits (a missing readiness binary,
# a transient sudo/pgrep hiccup), Kasm treats the whole session as failed to
# provision. Every external call below is guarded so a single bad check can
# only skip an iteration, never kill the script.
#
# Kasm executes this at session start. DISABLE_CUSTOM_STARTUP=true skips the
# watchdog loop entirely (e.g. while debugging a stuck session).
###############################################################################

log() { echo "[dind-startup] $*"; }

if [ -n "${DISABLE_CUSTOM_STARTUP:-}" ]; then
    log "DISABLE_CUSTOM_STARTUP set; not starting supervisord."
    exit 0
fi

# Best-effort: if Kasm's readiness binaries aren't present in this particular
# base image, don't block (or crash) on them - just proceed.
wait_for_desktop() {
    if command -v filter_ready >/dev/null 2>&1; then
        filter_ready || true
    fi
    if command -v desktop_ready >/dev/null 2>&1; then
        desktop_ready || true
    fi
}

log "Entering supervisord watchdog loop..."
while true; do
    if ! pgrep -x supervisord >/dev/null 2>&1; then
        wait_for_desktop
        log "Starting supervisord (manages dockerd - see /etc/supervisor/conf.d/dockerd.conf)"
        sudo /usr/bin/supervisord -n >>/var/log/dind-supervisord-watchdog.log 2>&1 &
    fi
    sleep 2
done
