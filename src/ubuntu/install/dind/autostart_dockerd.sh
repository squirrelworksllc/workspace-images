#!/usr/bin/env bash
###############################################################################
# autostart_dockerd.sh
#
# Installed to /usr/local/bin/dind-autostart-dockerd and launched from the XFCE
# session via /etc/xdg/autostart/dind-dockerd.desktop - i.e. once the desktop
# is up. It touches nothing that Kasm owns (no /dockerstartup, no session
# scripts).
#
# By the time this runs Kasm has already created the container, generated its
# nginx proxy config and handed the live session to the user - so starting
# dockerd (and letting it set up its docker0 bridge / iptables rules) this late
# can no longer race Kasm's provisioning. If the daemon is slow or unhappy, the
# desktop is already usable.
#
# Runs as the session user (uid 1000); dockerd is started through `sudo`
# (see /etc/sudoers.d/dind-dockerd). The Kasm dockerd-entrypoint.sh execs
# dockerd in the foreground, so it is backgrounded here. A sentinel keeps it to
# one start per session.
#
# Toggle:  DOCKERD_AUTOSTART=false  leaves the daemon stopped.
###############################################################################
set -uo pipefail

LOG="/var/log/dockerd.log"
SENTINEL="/tmp/.dind-autostart-dockerd.done"
ENTRYPOINT="/usr/local/bin/dockerd-entrypoint.sh"

tag() { echo "[dind-autostart] $(date -Is) $*" >>"$LOG" 2>/dev/null || true; }

# One start per session.
if ! ( set -o noclobber; : >"$SENTINEL" ) 2>/dev/null; then
    exit 0
fi

if [ "${DOCKERD_AUTOSTART:-true}" != "true" ]; then
    tag "DOCKERD_AUTOSTART=${DOCKERD_AUTOSTART:-<unset>}; leaving the Docker daemon stopped"
    exit 0
fi

if [ ! -x "$ENTRYPOINT" ]; then
    tag "ERROR: ${ENTRYPOINT} missing; cannot start the Docker daemon"
    exit 0
fi

if docker info >/dev/null 2>&1; then
    tag "Docker daemon already running; nothing to do"
    exit 0
fi

# Belt-and-suspenders: the autostart entry fires from xfce4-session, so the
# desktop already exists here; give it a moment to finish painting.
for _ in $(seq 1 20); do
    pgrep -x xfce4-session >/dev/null 2>&1 && break
    pgrep -x xfwm4         >/dev/null 2>&1 && break
    sleep 1
done
sleep 3

tag "starting the Docker daemon via ${ENTRYPOINT}"
nohup sudo -n "$ENTRYPOINT" </dev/null >>"$LOG" 2>&1 &

for _ in $(seq 1 30); do
    [ -S /var/run/docker.sock ] && break
    sleep 1
done

if [ -S /var/run/docker.sock ]; then
    tag "Docker daemon is up (socket: /var/run/docker.sock)"
    if command -v notify-send >/dev/null 2>&1; then
        DISPLAY="${DISPLAY:-:1}" notify-send -u low "Docker" "The nested Docker daemon is ready." 2>/dev/null || true
    fi
else
    tag "WARNING: docker.sock did not appear within 30s. The container may not be"
    tag "         running privileged, or dockerd failed - see the log above."
fi
