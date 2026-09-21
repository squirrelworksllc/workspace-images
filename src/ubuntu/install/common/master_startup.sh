#!/usr/bin/env bash
###############################################################################
# SquirrelWorks 1.1 - Master Startup Orchestrator
#
# PURPOSE:
# This is the centralized logic engine that iterates through all installed 
# application modules and executes their respective 'startup.sh' scripts.
#
# ARCHITECTURAL ROLE:
# Instead of hardcoding every service launch into a single monolithic script,
# this orchestrator scans the standard SquirrelWorks directory structure:
#   /dockerstartup/install/ubuntu/install/[APP_NAME]/startup.sh
#
# DESIGN PRINCIPLES:
# 1. ATOMICITY: Each application manages its own runtime needs.
# 2. ERROR ISOLATION: A failure in one app module's startup logic will 
#    be logged, but will not prevent the rest of the desktop from loading.
# 3. IDEMPOTENCY: Leverages a session-level guard file (/tmp/kasm_startup_complete)
#    to prevent re-initialization during session reconnects.
# 4. TRACEABILITY: Logs the start and end of every module to /tmp/kasm_startup.log
#    for rapid troubleshooting.
#
# USAGE:
# Called by the primary /dockerstartup/startup/custom_startup.sh script.
###############################################################################
set -e

log() { echo "[MASTER-STARTUP] $*"; }

# Guard: Ensure we only run once per session
if [ -f /tmp/kasm_startup_complete ]; then
    log "Session already initialized. Skipping."
    exit 0
fi

log "Starting SquirrelWorks Runtime Initialization..."

# 1. Sync Permissions (Crucial if using Kasm Persistent Profiles)
# Kasm Noble runs the session user with primary group 0, so stay consistent
# with 01_cleanup.sh / the Dockerfiles and use 1000:0 (not 1000:1000).
# Best-effort: custom_startup.sh may run unprivileged, and a failed chown here
# must not abort the module loop below (script runs under `set -e`).
KASM_HOME=$(getent passwd 1000 | cut -d: -f6)
chown 1000:0 "$KASM_HOME" 2>/dev/null || true

# 2. Iterate and Execute
# This finds any 'startup.sh' in the app subdirectories
INSTALL_ROOT="/dockerstartup/install/ubuntu/install"
find "$INSTALL_ROOT" -maxdepth 2 -name "startup.sh" -type f | sort | while read -r script; do
    APP_NAME=$(basename "$(dirname "$script")")
    log "Initializing module: [$APP_NAME]"
    bash "$script" || log "ERROR: Module [$APP_NAME] failed to initialize."
done

touch /tmp/kasm_startup_complete
log "Initialization complete. Desktop is ready."
