#!/usr/bin/env bash
###############################################################################
# install_qbittorrent.sh
# Purpose: Installs qBittorrent with "No-Seed" Enforcement for SquirrelWorks
###############################################################################
set -euo pipefail
: "${INST_DIR:=/dockerstartup/install}"
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[QBITTORRENT-INSTALL] $*"; }

main() {
    log "======= Installing qBittorrent (No-Seed Policy) ======="

    apt_update_if_needed
    apt_install software-properties-common
    add-apt-repository -y ppa:qbittorrent-team/qbittorrent-stable
    apt_refresh_after_repo_change
    apt_install qbittorrent

    # The config file persists into the *running* session home, so its baked
    # paths must reference the runtime home (/home/kasm-user), not the build
    # home (getent passwd 1000 -> /home/kasm-default-profile).
    RUNTIME_HOME="/home/kasm-user"

    log "Injecting no-seed / segmented-download profile..."
    SKEL_CONF_DIR="/etc/skel/.config/qBittorrent"
    USER_CONF_DIR="${RUNTIME_HOME}/.config/qBittorrent"
    mkdir -p "$SKEL_CONF_DIR" "$USER_CONF_DIR"

    cat <<EOF > "$SKEL_CONF_DIR/qBittorrent.conf"
[LegalNotice]
Accepted=true

[Preferences]
BitTorrent\MaxRatioAction=1
BitTorrent\MaxRatio=0
Connection\PortRangeMin=6881
Downloads\SavePath=${RUNTIME_HOME}/Downloads/complete
Downloads\CustomSaveFolderHistory=${RUNTIME_HOME}/Downloads/complete
Downloads\TempPath=${RUNTIME_HOME}/Downloads/in_progress
Downloads\TempPathEnabled=true
Downloads\FinishedTorrentExportDir=${RUNTIME_HOME}/Downloads/torrents
Downloads\FinishedTorrentExportDirEnabled=true
Queueing\MaxActiveDownloads=-1
Queueing\MaxActiveUploads=-1
Queueing\MaxActiveTorrents=-1
Queueing\QueueingEnabled=false
WebUI\Enabled=false
EOF
    cp "$SKEL_CONF_DIR/qBittorrent.conf" "$USER_CONF_DIR/qBittorrent.conf"

    # Segmented storage pipeline
    mkdir -p "${RUNTIME_HOME}/Downloads/complete" \
             "${RUNTIME_HOME}/Downloads/in_progress" \
             "${RUNTIME_HOME}/Downloads/torrents"

    # Ownership (Noble runs the session user with primary group 0)
    chown -R 1000:0 "${RUNTIME_HOME}/.config" "${RUNTIME_HOME}/Downloads" 2>/dev/null || true

    log "qBittorrent installation complete."
}

main "$@"
