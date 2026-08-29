#!/usr/bin/env bash
###############################################################################
# install_gimp.sh
# Purpose: Installs GIMP (AppImage Extract) dynamically for SquirrelWorks 1.1
###############################################################################
set -euo pipefail
LOG_TAG="GIMP-INSTALL"
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/03_scaffold.sh"

main() {
    log "======= Installing GIMP (AppImage Extract) ======="

    ARCH="$(dpkg --print-architecture)"
    apt_update_if_needed
    # Added curl and wget to ensure they are present for the scraper
    apt_install libfuse2 libglib2.0-0 curl wget

    mkdir -p /opt/gimp
    cd /opt/gimp

    # 1. Dynamically find the highest release branch (e.g., 3.2, 3.4)
    log "Detecting latest GIMP release branch..."
    GIMP_BRANCH=$(curl -s https://download.gimp.org/gimp/ | grep -oP '(?<=href="v)[0-9]+\.[0-9]+(?=/")' | sort -V | tail -n 1 || true)
    
    # Fallback if the root directory scrape fails
    if [ -z "${GIMP_BRANCH}" ]; then
        log "WARNING: Could not auto-detect branch. Falling back to 3.2."
        GIMP_BRANCH="3.2"
    fi

    # 2. Scan that specific branch for the latest AppImage version
    log "Scanning branch v${GIMP_BRANCH} for latest AppImage..."
    GIMP_VERSION=$(curl -s "https://download.gimp.org/gimp/v${GIMP_BRANCH}/linux/" | grep -oP "GIMP-\K${GIMP_BRANCH}\.[0-9]+(?=-x86_64\.AppImage)" | sort -V | tail -n 1 || true)

    # 3. Final fallback if the sub-directory scrape fails
    if [ -z "${GIMP_VERSION}" ]; then
        log "WARNING: Could not auto-detect version. Falling back to safe known version."
        GIMP_BRANCH="3.2"
        GIMP_VERSION="3.2.4"
    fi

    log "Downloading GIMP ${GIMP_VERSION} from branch v${GIMP_BRANCH}..."
    if [ "${ARCH}" = "amd64" ]; then
        URL="https://download.gimp.org/gimp/v${GIMP_BRANCH}/linux/GIMP-${GIMP_VERSION}-x86_64.AppImage"
    else
        URL="https://download.gimp.org/gimp/v${GIMP_BRANCH}/linux/GIMP-${GIMP_VERSION}-aarch64.AppImage"
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

    run_configure_ui
    log "GIMP installation complete."
}

main "$@"
