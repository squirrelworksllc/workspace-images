#!/usr/bin/env bash
###############################################################################
# install_tesseract_ocr.sh
#
# Purpose: Installs Tesseract OCR and NormCap.
###############################################################################
set -euo pipefail
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[TESSERACT-INSTALL] $*"; }

log "======= Installing Tesseract OCR Environment ======="

log "Step 1: Installing system packages..."
apt_update_if_needed

apt_install \
  tesseract-ocr \
  tesseract-ocr-eng \
  libtesseract-dev \
  libleptonica-dev \
  python3-venv \
  build-essential \
  python3-opencv \
  wl-clipboard \
  gimagereader

log "Step 2: Installing normcap into /opt/venv..."
python3 -m venv /opt/venv
/opt/venv/bin/pip install --no-cache-dir --upgrade pip
/opt/venv/bin/pip install --no-cache-dir normcap
ln -sf /opt/venv/bin/normcap /usr/local/bin/normcap

log "Step 3: Triggering UI configuration..."
# Dynamically find the script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "${SCRIPT_DIR}/configure_ui.sh"

log "Tesseract OCR Environment installation complete!"
