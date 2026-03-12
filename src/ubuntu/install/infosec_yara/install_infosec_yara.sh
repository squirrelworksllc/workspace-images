#!/usr/bin/env bash
###############################################################################
# install_infosec_yara.sh
# Purpose: Installs YARA engine, YLS (Language Server), and Python tooling.
###############################################################################
set -euo pipefail
: "${INST_DIR:=/dockerstartup/install}"
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[YARA-INSTALL] $*"; }

main() {
    log "======= Installing YARA Malware Analysis Environment ======="

    log "Step 1: Installing YARA core and Python dependencies..."
    apt_update_if_needed
    apt_install yara python3-pip python3-venv libyara-dev

    log "Step 2: Creating specialized VirtualEnv for YARA Language Server (YLS)..."
    # We use /opt/yara-tools to keep /usr/bin clean
    mkdir -p /opt/yara-tools
    python3 -m venv /opt/yara-tools/venv
    /opt/yara-tools/venv/bin/pip install --no-cache-dir --upgrade pip
    /opt/yara-tools/venv/bin/pip install --no-cache-dir yls-yara plyara yara-python

    # Symlink the Language Server so VS Code finds it on the system PATH
    ln -sf /opt/yara-tools/venv/bin/yls /usr/local/bin/yls

    log "Step 3: Triggering UI and VS Code integration..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "${SCRIPT_DIR}/configure_ui.sh" ]; then
        bash "${SCRIPT_DIR}/configure_ui.sh"
    fi

    log "YARA environment installation complete."
}

main "$@"
