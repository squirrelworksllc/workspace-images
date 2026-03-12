#!/usr/bin/env bash
###############################################################################
# install_gimp.sh
# Purpose: Installs GIMP 3.x (AppImage Extract) for SquirrelWorks 1.1
###############################################################################
set -euo pipefail
: "${INST_DIR:=/dockerstartup/install}"
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[GIMP-INSTALL] $*"; }

main() {
    log "======= Installing GIMP (AppImage Extract) ======="

    ARCH="$(dpkg --print-architecture)"
    apt_update_if_needed
    apt_install libfuse2 libglib2.0-0

    mkdir -p /opt/gimp
    cd /opt/gimp

    # Improved version detection for the v3.0 stable release
    log "Detecting latest GIMP 3 stable version..."
    GIMP_VERSION=$(curl -s https://download.gimp.org/gimp/v3.0/linux/ | grep -oP 'GIMP-\K[0-9.]+(?=-x86_64.AppImage)' | head -n1)

    if [ -z "${GIMP_VERSION}" ]; then
        log "WARNING: Could not auto-detect version. Falling back to 3.0.0."
        GIMP_VERSION="3.0.0"
    fi

    log "Downloading GIMP ${GIMP_VERSION}..."
    if [ "${ARCH}" = "amd64" ]; then
        URL="https://download.gimp.org/gimp/v3.0/linux/GIMP-${GIMP_VERSION}-x86_64.AppImage"
    else
        URL="https://download.gimp.org/gimp/v3.0/linux/GIMP-${GIMP_VERSION}-aarch64.AppImage"
    fi

    wget -q "$URL" -O gimp.AppImage
    chmod +x gimp.AppImage

    log "Extracting AppImage to /opt/gimp/app..."
    ./gimp.AppImage --appimage-extract
    mv squashfs-root app
    rm -f gimp.AppImage

    log "Creating sandbox-friendly launcher..."
    cat > /opt/gimp/launcher <<'EOF'
#!/usr/bin/env bash
exec /opt/gimp/app/AppRun --no-sandbox "$@"
EOF
    chmod +x /opt/gimp/launcher

    log "Triggering UI configuration..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "${SCRIPT_DIR}/configure_ui.sh" ]; then
        bash "${SCRIPT_DIR}/configure_ui.sh"
    fi

    log "GIMP installation complete."
}

main "$@"
