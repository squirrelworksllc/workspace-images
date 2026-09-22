#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
# Purpose: Silences Recoll first-run wizard and sets Kasm Desktop icons.
###############################################################################
set -euo pipefail

log() { echo "[RECOLL-UI] $*"; }

KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")
# shellcheck source=/dev/null
source "${INST_DIR:-/dockerstartup/install}/ubuntu/install/common/10_desktop_icon.sh"

log "Step 1: Pre-configuring Recoll to skip first-run prompts..."
RECOLL_CONF_DIR="$KASM_HOME/.recoll"
mkdir -p "$RECOLL_CONF_DIR"

# This file tells Recoll NOT to show the indexing setup wizard.
# We also set it to only index the user's home by default, not the whole system.
cat <<EOF > "$RECOLL_CONF_DIR/recoll.conf"
topdirs = ~
skippedNames = .thumbnails .cache .wine .config .local
idxflushthreshold = 10
EOF

log "Step 2: Menu + Desktop integration..."
# Recoll might ship 'recoll.desktop' or 'recollgui.desktop'
DESKTOP_SRC="/usr/share/applications/recoll.desktop"
[ -f "$DESKTOP_SRC" ] || DESKTOP_SRC="/usr/share/applications/recollgui.desktop"

if [ -f "$DESKTOP_SRC" ]; then
    # Move the menu entry into the Graphics category.
    sed -i 's/Categories=.*/Categories=Graphics;Utility;/g' "$DESKTOP_SRC"
    if command -v update-desktop-database > /dev/null; then
        update-desktop-database /usr/share/applications/
    fi
fi

# Desktop icon (opt-in via RECOLL_DESKTOP_ICON=true; default off)
desktop_icon recoll "$DESKTOP_SRC" false Recoll.desktop

chown -R 1000:0 "$KASM_HOME/.recoll" 2>/dev/null || true

log "Recoll UI configuration complete."
