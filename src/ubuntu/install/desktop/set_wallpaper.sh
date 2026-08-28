#!/usr/bin/env bash
###############################################################################
# SquirrelWorks 1.1 - Wallpaper Selection Module
# Usage: ./set_wallpaper.sh [noble|remnux|bitcurator5]
###############################################################################
set -euo pipefail

log() { echo -e "\n\033[1;35m[WALLPAPER]\033[0m $*"; }

THEME="${1:-noble}" # Default to noble if no arg provided
REPO_RESOURCES="${INST_DIR:-/dockerstartup/install}/ubuntu/resources/images"
TARGET_IMG="/usr/share/backgrounds/bg_default.png"

FALLBACK_IMG="${REPO_RESOURCES}/noble_numbat_bg.png"
case "$THEME" in
    remnux)      SOURCE_IMG="${REPO_RESOURCES}/remnux_bg.png" ;;
    bitcurator5) SOURCE_IMG="${REPO_RESOURCES}/bitcurator5_bg.png" ;;
    noble)       SOURCE_IMG="${FALLBACK_IMG}" ;;
    *) log "ERROR: Unknown theme: $THEME"; exit 1 ;;
esac

log "Applying ${THEME} branding to $TARGET_IMG..."

# A missing theme asset must not fail a build - fall back to the default.
if [[ ! -f "$SOURCE_IMG" && -f "$FALLBACK_IMG" ]]; then
    log "WARNING: ${SOURCE_IMG} not found; using default noble wallpaper."
    SOURCE_IMG="$FALLBACK_IMG"
fi

if [[ -f "$SOURCE_IMG" ]]; then
    mkdir -p /usr/share/backgrounds
    cp -f "$SOURCE_IMG" "$TARGET_IMG"
    chmod 644 "$TARGET_IMG"
    log "Branding applied from $(basename "$SOURCE_IMG")."
else
    log "WARNING: no wallpaper source available; leaving the default in place."
fi
