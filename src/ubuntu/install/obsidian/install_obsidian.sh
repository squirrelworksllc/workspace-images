#!/usr/bin/env bash
###############################################################################
# install_obsidian.sh
# Purpose: Installs Obsidian (official .deb) for SquirrelWorks 1.1
###############################################################################
set -euo pipefail
: "${INST_DIR:=/dockerstartup/install}"
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[OBSIDIAN-INSTALL] $*"; }

# GitHub "releases/latest" is unreliable for Obsidian - mobile (APK) and desktop
# releases interleave, so "latest" is often an Android build with no .deb.
# Resolve the version from Obsidian's own desktop auto-update manifest instead
# (served from raw.githubusercontent.com, which is not API-rate-limited) and
# build the release-asset URL. Obsidian only ships a .deb for amd64.
OBSIDIAN_MANIFEST="https://raw.githubusercontent.com/obsidianmd/obsidian-releases/HEAD/desktop-releases.json"
OBSIDIAN_FALLBACK_VERSION="1.13.7"   # bump occasionally; only used if the manifest is unreachable

main() {
    log "======= Installing Obsidian ======="

    ARCH="$(dpkg --print-architecture)"
    apt_update_if_needed
    apt_install curl jq ca-certificates

    if [ "${ARCH}" != "amd64" ]; then
        log "Obsidian publishes a .deb for amd64 only; skipping on ${ARCH}."
        exit 0
    fi

    log "Step 1: Resolving latest desktop version..."
    VERSION="$(curl -fsSL --retry 3 "${OBSIDIAN_MANIFEST}" 2>/dev/null \
        | jq -r '.latestVersion // empty' || true)"
    if [ -z "${VERSION}" ]; then
        VERSION="${OBSIDIAN_FALLBACK_VERSION}"
        log "WARNING: could not read the manifest; falling back to ${VERSION}."
    fi
    log "Target version: ${VERSION}"

    DEB_URL="https://github.com/obsidianmd/obsidian-releases/releases/download/v${VERSION}/obsidian_${VERSION}_amd64.deb"

    log "Step 2: Downloading ${DEB_URL}"
    curl -fL --retry 3 --retry-delay 2 -o /tmp/obsidian.deb "${DEB_URL}"

    log "Step 3: Installing (apt resolves the Electron dependencies)..."
    apt-get install -y /tmp/obsidian.deb
    rm -f /tmp/obsidian.deb

    log "Step 4: Triggering UI and environment configuration..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "${SCRIPT_DIR}/configure_ui.sh" ]; then
        bash "${SCRIPT_DIR}/configure_ui.sh"
    fi

    log "Obsidian installation complete."
}

main "$@"
