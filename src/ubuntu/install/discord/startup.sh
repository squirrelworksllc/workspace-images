#!/usr/bin/env bash
###############################################################################
# SquirrelWorks 1.1 - Application Runtime Module
#
# APP: Discord
#
# PURPOSE:
# Forces Discord to skip its mandatory update check at boot.
###############################################################################
set -e

log() { echo "[DISCORD-STARTUP] $*"; }

KASM_HOME=$(getent passwd 1000 | cut -d: -f6 || echo "/home/kasm-default-profile")
DISCORD_CONF="$KASM_HOME/.config/discord"

log "Enforcing Discord update-skip policy..."

# 1. Ensure the directory exists
mkdir -p "$DISCORD_CONF"

# 2. Inject the Skip Update flag
# Using this method ensures we don't overwrite other user settings (like login)
if [ -f "$DISCORD_CONF/settings.json" ]; then
    # If file exists, use sed to ensure the key is true
    if grep -q "SKIP_HOST_UPDATE" "$DISCORD_CONF/settings.json"; then
        sed -i 's/"SKIP_HOST_UPDATE": false/"SKIP_HOST_UPDATE": true/g' "$DISCORD_CONF/settings.json"
    else
        # Key missing? Insert it.
        sed -i 's/{/{"SKIP_HOST_UPDATE": true, /' "$DISCORD_CONF/settings.json"
    fi
else
    # File doesn't exist? Create it fresh.
    echo '{"SKIP_HOST_UPDATE": true}' > "$DISCORD_CONF/settings.json"
fi

# 3. Final Permission Sync (best-effort: custom_startup.sh may run unprivileged)
chown -R 1000:0 "$DISCORD_CONF" 2>/dev/null || true

log "Discord is shielded from host updates. Ready to launch."
