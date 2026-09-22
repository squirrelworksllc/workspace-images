#!/usr/bin/env bash
###############################################################################
# install_telegram.sh
# Purpose: Installs Telegram Desktop (tarball on amd64, apt on legacy arm64).
###############################################################################
set -euo pipefail
LOG_TAG="TELEGRAM-INSTALL"
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/03_scaffold.sh"

install_via_apt() {
    . /etc/os-release
    if [ "${VERSION_CODENAME:-}" = "noble" ] || [ "${VERSION_CODENAME:-}" = "trixie" ]; then
        log "telegram-desktop is not in apt for ${VERSION_CODENAME}; skipping."
        exit 0
    fi
    apt_update_if_needed
    apt_install telegram-desktop
}

install_via_tarball() {
    apt_update_if_needed
    log "Downloading + extracting the Telegram tarball into /opt..."
    curl -fsSL --retry 3 https://telegram.org/dl/desktop/linux -o /tmp/telegram.tgz
    rm -rf /opt/Telegram
    tar -xf /tmp/telegram.tgz -C /opt/
    rm -f /tmp/telegram.tgz
    ln -sf /opt/Telegram/Telegram /usr/local/bin/telegram
}

main() {
    require_root
    log "======= Installing Telegram ======="

    if [ "$(dpkg --print-architecture)" = "arm64" ]; then
        install_via_apt
    else
        install_via_tarball
    fi

    run_configure_ui
    log "Telegram install complete."
}

main "$@"
