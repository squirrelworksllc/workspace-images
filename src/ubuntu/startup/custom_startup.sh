#!/usr/bin/env bash
###############################################################################
# SquirrelWorks 1.1 - Custom Startup Orchestrator
#
# PURPOSE:
# This script is the final "Handshake" between the Kasm Workspaces Agent
# and the user session. It handles dynamic, runtime-only configurations 
# that cannot be baked into the static Docker image layers.
#
# WHY IS THIS NEEDED?
# 1. PERMISSIONS: Kasm volume mounts (Persistent Profiles) often reset 
#    UID 1000 permissions. This script enforces ownership at boot.
# 2. DAEMONS: Starts background services that don't use standard init
#    (e.g., Tor, SSH agents, or custom database engines).
# 3. ENVIRONMENT: Injects dynamic variables (Display, Path, or Proxies) 
#    required by the desktop environment before XFCE initializes.
# 4. MODULARITY: This script acts as a "Master Trigger," scanning app 
#    folders for individual 'startup.sh' modules to keep images lean.
#
# EXECUTION:
# Automatically executed by the Kasm Agent as the container user.
# Uses a /tmp/ guard to ensure logic only runs once per session.
###############################################################################

# KASM Entry Point
set -e
# Call the actual logic sitting in your install folder
bash /dockerstartup/install/ubuntu/install/common/master_startup.sh

# Runtime validation - runs the modular validators after the per-app startup
# modules (daemons) have had a chance to come up. Soft by default; export
# VALIDATE_MODE=hard to make a failing check abort session startup.
# (Harmless if a Kasm workspace.json exec hook also invokes it - it is read-only.)
if [ -x /dockerstartup/tools/runtime_validation.sh ]; then
  bash /dockerstartup/tools/runtime_validation.sh
fi
