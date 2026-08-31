#!/usr/bin/env bash
###############################################################################
# start_dockerd.sh
#
# Installed to /usr/local/bin/dind-start-docker and run on demand from the
# "Docker in Docker" desktop / menu launcher. The nested Docker daemon is NOT
# started automatically at session login - the user starts it from here when
# they need it.
#
# Runs as the session user (uid 1000); dockerd is started through `sudo`
# (one whitelisted command in /etc/sudoers.d/dind-dockerd). The Kasm
# dockerd-entrypoint.sh execs dockerd in the foreground, so it is backgrounded.
#
# Meant to run inside a terminal (the launcher uses `xfce4-terminal --hold`),
# so it prints progress to stdout as well as /var/log/dockerd.log.
###############################################################################
set -uo pipefail

LOG="/var/log/dockerd.log"
ENTRYPOINT="/usr/local/bin/dockerd-entrypoint.sh"

say() {
    printf '%s\n' "$*"
    echo "[dind-start] $(date -Is) $*" >>"$LOG" 2>/dev/null || true
}

if docker info >/dev/null 2>&1; then
    say "The Docker daemon is already running."
    docker version 2>/dev/null | sed -n '1,12p'
    exit 0
fi

if [ ! -x "$ENTRYPOINT" ]; then
    say "ERROR: ${ENTRYPOINT} is missing - cannot start the Docker daemon."
    exit 1
fi

say "Starting the nested Docker daemon (this needs a privileged container)..."
nohup sudo -n "$ENTRYPOINT" </dev/null >>"$LOG" 2>&1 &

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
