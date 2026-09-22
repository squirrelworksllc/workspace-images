#!/usr/bin/env bash
###############################################################################
# 10_desktop_icon.sh   (sourced helper - defines desktop_icon)
#
# Place or remove a per-app Desktop shortcut based on an opt-in env toggle, so
# an image can turn individual icons on or off without editing app scripts.
#
#   source "${INST_DIR:-/dockerstartup/install}/ubuntu/install/common/10_desktop_icon.sh"
#   desktop_icon firefox  /usr/share/applications/firefox.desktop  true
#   desktop_icon vs_code   /usr/share/applications/code.desktop     false  code.desktop
#
#   desktop_icon <name> <source.desktop> <default: true|false> [dest-basename]
#
# Toggle env var:  <NAME>_DESKTOP_ICON = true | false
#   ('-' and '.' -> '_', letters upper-cased: tor_browser -> TOR_BROWSER_DESKTOP_ICON)
# When the var is unset, <default> decides.
###############################################################################

desktop_icon() {
    local name="$1" src="$2" default="${3:-false}" dest="${4:-}"
    [ -n "$dest" ] || dest="$(basename "$src")"

    local var val home
    var="$(printf '%s_DESKTOP_ICON' "$name" | tr 'a-z.-' 'A-Z__')"
    val="${!var:-$default}"
    home="$(getent passwd 1000 2>/dev/null | cut -d: -f6 || true)"
    [ -n "$home" ] || home="/home/kasm-default-profile"

    if [ "$val" = "true" ]; then
        if [ ! -f "$src" ]; then
            echo "[desktop-icon] ${name}: enabled but ${src} not found - skipped"
            return 0
        fi
        echo "[desktop-icon] ${name}: enabled -> ${home}/Desktop/${dest}"
        mkdir -p "${home}/Desktop"
        cp -f "$src" "${home}/Desktop/${dest}"
        chmod 0755 "${home}/Desktop/${dest}"
        chown 1000:0 "${home}/Desktop/${dest}" 2>/dev/null || true
    else
        echo "[desktop-icon] ${name}: disabled (Applications-menu entry kept)"
        rm -f "${home}/Desktop/${dest}"
    fi
}
