#!/usr/bin/env bash
###############################################################################
# configure_ui.sh
# Purpose: Silences Recoll first-run wizard and sets Kasm Desktop icons.
###############################################################################
set -euo pipefail

log() { echo "[RECOLL-UI] $*"; }

KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")

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

log "Step 2: Deploying Desktop Shortcut..."
# Recoll might use 'recoll.desktop' or 'recollgui.desktop'
DESKTOP_SRC="/usr/share/applications/recoll.desktop"
[ ! -f "$DESKTOP_SRC" ] && DESKTOP_SRC="/usr/share/applications/recollgui.desktop"

if [ -f "$DESKTOP_SRC" ]; then
    mkdir -p "$KASM_HOME/Desktop"
    cp "$DESKTOP_SRC" "$KASM_HOME/Desktop/Recoll.desktop"
    chmod +x "$KASM_HOME/Desktop/Recoll.desktop"
    
    log "Categorizing Start Menu entry..."
    sed -i 's/Categories=.*/Categories=System;Filesystem;Utility;Search;/g' "$DESKTOP_SRC"
fi

chown -R 1000:1000 "$KASM_HOME/.recoll" "$KASM_HOME/Desktop"

log "Recoll UI configuration complete."
