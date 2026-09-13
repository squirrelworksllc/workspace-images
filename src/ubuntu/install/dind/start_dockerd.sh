#!/usr/bin/env bash
###############################################################################
# start_dockerd.sh
#
# Installed to /usr/local/bin/dind-start-docker and run on demand from the
# "Docker in Docker" desktop / menu launcher. The nested Docker daemon is NOT
# started automatically at session login - overriding Kasm's own
# /dockerstartup/custom_startup.sh for that purpose reproducibly broke session
# provisioning ("Nginx failed to reload... no host in upstream") even once the
# script itself was made crash-proof, so this repo does not touch that file.
#
# Starts supervisord (see /etc/supervisor/conf.d/dockerd.conf), which then
# manages dockerd-entrypoint.sh as a supervised, auto-restarting child - if
# dockerd ever dies later in the session, supervisord brings it back without
# the user re-running this launcher.
#
# Meant to run inside a terminal (the launcher uses `xfce4-terminal --hold`),
# so it prints progress to stdout as well as to the log file.
###############################################################################
set -uo pipefail

LOG="/var/log/dind-supervisord.log"

say() {
    printf '%s\n' "$*"
    echo "[dind-start] $(date -Is) $*" >>"$LOG" 2>/dev/null || true
}

if docker info >/dev/null 2>&1; then
    say "The Docker daemon is already running."
    docker version 2>/dev/null | sed -n '1,12p'
    exit 0
fi

if pgrep -x supervisord >/dev/null 2>&1; then
    say "supervisord is already running; waiting for the Docker socket..."
else
    say "Starting supervisord (manages dockerd - see /etc/supervisor/conf.d/dockerd.conf)..."
    nohup sudo /usr/bin/supervisord -n >>"$LOG" 2>&1 &
fi

for _ in $(seq 1 30); do
    [ -S /var/run/docker.sock ] && break
    sleep 1
done

if [ -S /var/run/docker.sock ]; then
    say "Docker daemon is up."
    docker version 2>/dev/null | sed -n '1,12p'
    if command -v notify-send >/dev/null 2>&1; then
        DISPLAY="${DISPLAY:-:1}" notify-send -u low "Docker" "The nested Docker daemon is ready." 2>/dev/null || true
    fi
    exit 0
fi

say ""
say "WARNING: /var/run/docker.sock did not appear within 30s."
say "The container may not be running privileged, or dockerd failed to start."
say "Last 30 lines of ${LOG}:"
tail -n 30 "$LOG" 2>/dev/null || true
exit 1
