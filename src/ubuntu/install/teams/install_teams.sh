#!/usr/bin/env bash
###############################################################################
# install_teams.sh
# Purpose: Installs teams-for-linux from repo.teamsforlinux.de.
###############################################################################
set -euo pipefail
LOG_TAG="TEAMS-INSTALL"
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/03_scaffold.sh"

main() {
    log "======= Installing Microsoft Teams (teams-for-linux) ======="
    require_arch amd64

    . /etc/os-release
    case "${ID}" in
        ubuntu|debian|kali) ;;
        *) log "ERROR: Unsupported distro: ${ID}" >&2; exit 1 ;;
    esac

    apt_update_if_needed
    add_apt_repo teams-for-linux \
        "https://repo.teamsforlinux.de/teams-for-linux.asc" \
        "https://repo.teamsforlinux.de/debian/" "stable" "main"
    apt_install teams-for-linux

    run_configure_ui
    log "teams-for-linux installed!"
}

main "$@"
