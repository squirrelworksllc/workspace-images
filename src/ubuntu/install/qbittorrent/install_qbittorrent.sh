#!/usr/bin/env bash
###############################################################################
# install_qbittorrent.sh
# Purpose: Installs qBittorrent with "No-Seed" Enforcement for SquirrelWorks
###############################################################################
set -ex

# 1. Dependency Check & PPA Setup
apt-get update
apt-get install -y software-properties-common
add-apt-repository -y ppa:qbittorrent-team/qbittorrent-stable
apt-get update
apt-get install -y qbittorrent

# 2. Dynamic Kasm User Detection
# Detects 'kasm-user' (hyphen) or 'kasm_user' (underscore) dynamically
if id "kasm-user" &>/dev/null; then
    KASM_USER="kasm-user"
elif id "kasm_user" &>/dev/null; then
    KASM_USER="kasm_user"
else
    KASM_USER="kasm_user" # Fallback default
fi

USER_HOME="/home/${KASM_USER}"

# 3. Configuration Injection (System-Wide Skeleton)
# Ensures new ephemeral desktop sessions inherit these exact settings
SKEL_CONF_DIR="/etc/skel/.config/qBittorrent"
mkdir -p "$SKEL_CONF_DIR"

cat <<EOF > "$SKEL_CONF_DIR/qBittorrent.conf"
[LegalNotice]
Accepted=true

[Preferences]
BitTorrent\MaxRatioAction=1
BitTorrent\MaxRatio=0
Connection\PortRangeMin=6881
Downloads\SavePath=${USER_HOME}/Downloads/complete
Downloads\CustomSaveFolderHistory=${USER_HOME}/Downloads/complete
Downloads\TempPath=${USER_HOME}/Downloads/in_progress
Downloads\TempPathEnabled=true
Downloads\FinishedTorrentExportDir=${USER_HOME}/Downloads/torrents
Downloads\FinishedTorrentExportDirEnabled=true
Queueing\MaxActiveDownloads=-1
Queueing\MaxActiveUploads=-1
Queueing\MaxActiveTorrents=-1
Queueing\QueueingEnabled=false
WebUI\Enabled=false
EOF

# 4. Initialize Active Build Layer Profiles
USER_CONF_DIR="${USER_HOME}/.config/qBittorrent"
mkdir -p "$USER_CONF_DIR"
cp "$SKEL_CONF_DIR/qBittorrent.conf" "$USER_CONF_DIR/qBittorrent.conf"

# Create the explicit segmented storage pipeline directories
mkdir -p "${USER_HOME}/Downloads/complete"
mkdir -p "${USER_HOME}/Downloads/in_progress"
mkdir -p "${USER_HOME}/Downloads/torrents"

# 5. Precise Permission Enforcement (UID/GID 1000)
chown -R 1000:1000 "${USER_HOME}/.config"
chown -R 1000:1000 "${USER_HOME}/Downloads"

# 6. Global Layers Clean-Up Optimization
apt-get clean
rm -rf /var/lib/apt/lists/*
