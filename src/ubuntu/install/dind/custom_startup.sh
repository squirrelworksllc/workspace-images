#!/usr/bin/env bash
###############################################################################
# custom_startup.sh  (DinD)
#
# Kasm runs this once per session at startup, after the container is already
# provisioned and its nginx proxy config generated. Keep it non-blocking: kick
# the deferred dockerd launch into the background and return immediately so the
# desktop is never held up. dind-autostart-dockerd waits for the desktop itself
# before it starts the daemon, and a sentinel keeps it to one run per session
# (an XFCE autostart entry fires the same script).
###############################################################################
nohup /usr/local/bin/dind-autostart-dockerd >/dev/null 2>&1 &
exit 0
