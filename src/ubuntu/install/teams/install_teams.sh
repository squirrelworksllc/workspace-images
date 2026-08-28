#!/usr/bin/env bash
###############################################################################
# install_teams.sh
#
# Purpose: Installs teams.
#
# Note: Common Pre-Requisite apt packages are called via install_tools.sh
###############################################################################
set -euo pipefail
: "${INST_DIR:=/dockerstartup/install}"
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log "======= Install Microsoft Teams (teams-for-linux) ======="

ARCH="$(dpkg --print-architecture)"
if [ "${ARCH}" != "amd64" ]; then
  log "teams-for-linux repo is amd64-only; skipping on ${ARCH}."
  exit 0
fi

. /etc/os-release
case "${ID}" in
  ubuntu|debian|kali) ;;
  *)
    log "Unsupported distro for teams-for-linux installer: ${ID}" >&2
    exit 1
    ;;
esac

log "Step 1: Install deps..."
apt_update_if_needed

log "Step 2: Add teams-for-linux repo..."
install -m 0755 -d /etc/apt/keyrings
wget -qO /etc/apt/keyrings/teams-for-linux.asc https://repo.teamsforlinux.de/teams-for-linux.asc
chmod a+r /etc/apt/keyrings/teams-for-linux.asc

cat >/etc/apt/sources.list.d/teams-for-linux-packages.sources <<'EOF'
Types: deb
URIs: https://repo.teamsforlinux.de/debian/
Suites: stable
Components: main
Signed-By: /etc/apt/keyrings/teams-for-linux.asc
Architectures: amd64
EOF

apt_refresh_after_repo_change

log "Step 3: Install teams-for-linux..."
apt_install teams-for-linux

log "Step 4: Triggering UI configuration..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "${SCRIPT_DIR}/configure_ui.sh"

log "teams-for-linux installed!"
