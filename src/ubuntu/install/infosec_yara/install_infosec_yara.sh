#!/usr/bin/env bash
# This script is designed to install the complete environment needed to test and/or develop YARA rules inside
# of a docker container. This includes a pre-defined Yara release, a Yara Language Server (YLS-Yara)
# and extensions for Visual Studio as well as commandline utilities.
# Although this script may work alone it was not designed to do so and was designed to be invoked via Dockerfile.
# This script assumes Ubuntu and/or pure debian.
set -euo pipefail
source ${INST_DIR}/ubuntu/install/common/00_apt_helper.sh

echo "======= Installing InfoSec Yara Environment (distro packages) ======="

# Hard-set the target home since the image is always used by kasm-user
KASM_HOME="/home/kasm-user"

echo "Step 1: Install Yara + Python tooling..."
apt_update_if_needed
apt_install \
  yara \
  python3 \
  python3-pip \
  python3-venv

# Optional: if your repos include it, this can be handy, but don't fail if missing
apt-get install -y yara-python 2>/dev/null || true

echo "Step 2: Create venv for Yara helpers..."
mkdir -p /opt/yara-env
python3 -m venv /opt/yara-env/env
/opt/yara-env/env/bin/pip install --no-cache-dir --upgrade pip
/opt/yara-env/env/bin/pip install --no-cache-dir yls-yara

# Convenience: put yls on PATH
ln -sf /opt/yara-env/env/bin/yls /usr/local/bin/yls

echo "Step 3: VS Code extensions for kasm-user (best effort)..."
if command -v code >/dev/null 2>&1; then
  mkdir -p "${KASM_HOME}/.config/Code" "${KASM_HOME}/.vscode/extensions"

  code --no-sandbox \
    --user-data-dir "${KASM_HOME}/.config/Code" \
    --extensions-dir "${KASM_HOME}/.vscode/extensions" \
    --install-extension infosec-intern.yara || true

  code --no-sandbox \
    --user-data-dir "${KASM_HOME}/.config/Code" \
    --extensions-dir "${KASM_HOME}/.vscode/extensions" \
    --install-extension avast-threatlabs-yara.vscode-yls || true

  chown -R 1000:1000 "${KASM_HOME}/.config/Code" "${KASM_HOME}/.vscode" 2>/dev/null || true
else
  echo "VS Code not found; skipping extension install."
fi

echo "InfoSec Yara Environment installed!"