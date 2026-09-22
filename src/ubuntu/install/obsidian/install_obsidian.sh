#!/usr/bin/env bash
###############################################################################
# install_obsidian.sh
# Purpose: Installs Obsidian (official .deb) for SquirrelWorks 1.1
#
# GitHub "releases/latest" is unreliable here - Obsidian interleaves mobile
# (APK) and desktop releases, so "latest" is often an Android build with no
# .deb. Resolve the version from Obsidian's own desktop auto-update manifest
# (raw.githubusercontent.com, not API-rate-limited) and build the asset URL.
# Obsidian only ships a .deb for amd64.
###############################################################################
set -euo pipefail
LOG_TAG="OBSIDIAN-INSTALL"
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/03_scaffold.sh"

OBSIDIAN_MANIFEST="https://raw.githubusercontent.com/obsidianmd/obsidian-releases/HEAD/desktop-releases.json"
OBSIDIAN_FALLBACK_VERSION="1.13.7"   # bump occasionally; used only if the manifest is unreachable

main() {
    log "======= Installing Obsidian ======="
    require_arch amd64

    apt_update_if_needed
    apt_install jq ca-certificates

    log "Resolving the latest desktop version..."
    local version
    version="$(curl -fsSL --retry 3 "${OBSIDIAN_MANIFEST}" 2>/dev/null | jq -r '.latestVersion // empty' || true)"
    if [ -z "${version}" ]; then
        version="${OBSIDIAN_FALLBACK_VERSION}"
        log "WARNING: could not read the manifest; falling back to ${version}."
    fi
    log "Target version: ${version}"

    install_deb "https://github.com/obsidianmd/obsidian-releases/releases/download/v${version}/obsidian_${version}_amd64.deb"

    run_configure_ui
    log "Obsidian installation complete."
}

main "$@"
