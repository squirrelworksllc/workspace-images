#!/usr/bin/env bash
# This script is designed to install the complete environment needed to run Tesseract Optical Character Recognition (OCR).
# Although this script may work alone it was not designed to do so and was designed to be invoked via Dockerfile.
# This script assumes Ubuntu and/or pure debian.
set -euo pipefail
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

echo "======= Installing Tesseract OCR Environment ======="

echo "Step 1: Installing packages..."
apt_update_if_needed

apt_install \
  tesseract-ocr \
  tesseract-ocr-eng \
  libtesseract-dev \
  libleptonica-dev \
  python3 \
  python3-pip \
  python3-venv \
  build-essential \
  python3-opencv \
  wl-clipboard \
  gimagereader

echo "Step 2: Installing normcap (venv)..."
python3 -m venv /opt/venv
/opt/venv/bin/pip install --no-cache-dir --upgrade pip
/opt/venv/bin/pip install --no-cache-dir normcap
ln -sf /opt/venv/bin/normcap /usr/local/bin/normcap

echo "Step 3: Desktop shortcuts..."
mkdir -p "$HOME/Desktop"

if [ -f /ubuntu/install/tesseract_ocr/tesseract.desktop ]; then
  cp /ubuntu/install/tesseract_ocr/tesseract.desktop "$HOME/Desktop/"
  chmod +x "$HOME/Desktop/tesseract.desktop" 2>/dev/null || true
  chown 1000:1000 "$HOME/Desktop/tesseract.desktop" 2>/dev/null || true
fi

if [ -f /ubuntu/install/tesseract_ocr/documentation.desktop ]; then
  cp /ubuntu/install/tesseract_ocr/documentation.desktop "$HOME/Desktop/"
  chmod +x "$HOME/Desktop/documentation.desktop" 2>/dev/null || true
  chown 1000:1000 "$HOME/Desktop/documentation.desktop" 2>/dev/null || true
fi

echo "Tesseract OCR Environment is now installed!"