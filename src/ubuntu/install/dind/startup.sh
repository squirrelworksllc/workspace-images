#!/usr/bin/env bash
###############################################################################
# SquirrelWorks 1.1 - Application Runtime Module
#
# APP: Docker-in-Docker (DinD)
#
# PURPOSE:
# This script initializes the Docker daemon inside the Kasm container.
#
# REQUIREMENT:
# The Kasm Workspaces Image must have 'Privileged' enabled in the Docker 
# run config for this to work.
###############################################################################
set -e

log() { echo "[DIND-STARTUP] $*"; }

# 1. Check for Privileged Mode
if [ ! -w /sys/fs/cgroup ]; then
    log "ERROR: Cannot start Docker. Container is not running in Privileged mode."
    exit 0 # We don't fail the whole session, we just skip Docker
fi

# 2. Start the Docker Daemon
if [ -x /usr/local/bin/dockerd-entrypoint.sh ]; then
    log "Starting Docker Daemon (dockerd)..."
    # We run this in the background as it is a persistent service
    nohup /usr/local/bin/dockerd-entrypoint.sh > /var/log/dockerd.log 2>&1 &
    
    # Wait for the socket to become available
    log "Waiting for Docker socket..."
    for i in {1..10}; do
        [ -S /var/run/docker.sock ] && break
        sleep 1
    done
    
    if [ -S /var/run/docker.sock ]; then
        log "Docker Daemon is LIVE."
        chmod 666 /var/run/docker.sock
    else
        log "WARNING: Docker Daemon failed to start within 10 seconds."
    fi
fi
