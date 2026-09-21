#!/usr/bin/env bash
###############################################################################
# install_tesseract_ocr.sh
# Purpose: Installs Tesseract OCR + NormCap.
###############################################################################
set -euo pipefail
LOG_TAG="TESSERACT-INSTALL"
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/03_scaffold.sh"

main() {
    log "======= Installing Tesseract OCR Environment ======="

    log "Step 1: System packages..."
    apt_update_if_needed
    apt_install \
        tesseract-ocr tesseract-ocr-eng libtesseract-dev libleptonica-dev \
        python3-venv build-essential python3-opencv wl-clipboard gimagereader

    log "Step 2: NormCap into /opt/venv..."
    python3 -m venv /opt/venv
    /opt/venv/bin/pip install --no-cache-dir --upgrade pip
    /opt/venv/bin/pip install --no-cache-dir normcap
    ln -sf /opt/venv/bin/normcap /usr/local/bin/normcap

    run_configure_ui
    log "Tesseract OCR Environment installation complete!"
}

main "$@"
