#!/usr/bin/env bash
###############################################################################
# install_vs_code.sh
# Purpose: Installs the Visual Studio Code .deb from the official channel.
###############################################################################
set -euo pipefail
LOG_TAG="VSCODE-INSTALL"
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/03_scaffold.sh"

main() {
    log "======= Installing VS Code ======="

    # VS Code uses "x64" naming; map the dpkg arch to its download token.
    local code_arch
    case "$(dpkg --print-architecture)" in
        amd64) code_arch="x64" ;;
        arm64) code_arch="arm64" ;;
        *) log "ERROR: unsupported arch $(dpkg --print-architecture)" >&2; exit 1 ;;
    esac

    apt_update_if_needed
    install_deb "https://update.code.visualstudio.com/latest/linux-deb-${code_arch}/stable"

    run_configure_ui
    log "VS Code installed!"
}

main "$@"
