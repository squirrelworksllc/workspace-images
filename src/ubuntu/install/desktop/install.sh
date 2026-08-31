#!/usr/bin/env bash
###############################################################################
# install.sh (Desktop Module)
# Purpose: Orchestrates system-wide branding, UI pinning, and documentation.
###############################################################################
set -euo pipefail

# In our new loop, the Dockerfile passes 'noble' or 'remnux' as $1
THEME="${1:-noble}"

log() { echo "[DESKTOP-INSTALL] $*"; }

log "======= Applying $THEME Desktop Environment Branding ======="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. Run the wallpaper replacement (The file-swap logic)
if [ -f "${SCRIPT_DIR}/set_wallpaper.sh" ]; then
    bash "${SCRIPT_DIR}/set_wallpaper.sh" "$THEME"
fi

# 2. Run the UI configuration (The XFCE pinning logic)
if [ -f "${SCRIPT_DIR}/configure_ui.sh" ]; then
    bash "${SCRIPT_DIR}/configure_ui.sh"
fi

# 3. Generate Local HTML Documentation & Package Manifests
# Skipped when GENERATE_DESKTOP_DOCS=false (e.g. the DinD image wants the
# branding/panel fixes but no app catalog).
if [ "${GENERATE_DESKTOP_DOCS:-true}" = "true" ] && [ -f "${SCRIPT_DIR}/generate_desktop_docs.sh" ]; then
    bash "${SCRIPT_DIR}/generate_desktop_docs.sh"
else
    log "Skipping documentation generation (GENERATE_DESKTOP_DOCS=${GENERATE_DESKTOP_DOCS:-true})."
fi

log "Desktop environment branding complete."
