#!/usr/bin/env bash
###############################################################################
# install_infosec_yara.sh
# Purpose: Installs the YARA engine, YLS (Language Server), and Python tooling.
###############################################################################
set -euo pipefail
LOG_TAG="YARA-INSTALL"
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/03_scaffold.sh"

main() {
    log "======= Installing YARA Malware Analysis Environment ======="

    log "Step 1: YARA core + Python deps..."
    apt_update_if_needed
    apt_install yara python3-pip python3-venv libyara-dev

    log "Step 2: YLS venv at /opt/yara-tools..."
    mkdir -p /opt/yara-tools
    python3 -m venv /opt/yara-tools/venv
    /opt/yara-tools/venv/bin/pip install --no-cache-dir --upgrade pip
    /opt/yara-tools/venv/bin/pip install --no-cache-dir yls-yara plyara yara-python
    # Put the language server on PATH so the VS Code extension finds it.
    ln -sf /opt/yara-tools/venv/bin/yls /usr/local/bin/yls

    run_configure_ui
    log "YARA environment installation complete."
}

main "$@"
