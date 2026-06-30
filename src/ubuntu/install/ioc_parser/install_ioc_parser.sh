#!/usr/bin/env bash
###############################################################################
# install.sh
# Purpose: Installs IOC Parser and its Python dependencies within a secure venv.
###############################################################################
set -euo pipefail
: "${INST_DIR:=/dockerstartup/install}"
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[IOC-PARSER-INSTALL] $*"; }

main() {
    log "======= Installing IOC Parser Environment ======="

    log "Step 1: Installing system prerequisites..."
    apt_update_if_needed
    apt_install python3-pip python3-venv

    log "Step 2: Creating specialized VirtualEnv for IOC Parser..."
    # Bypassing Ubuntu Noble's PEP 668 externally-managed-environment restrictions
    mkdir -p /opt/ioc-parser
    python3 -m venv /opt/ioc-parser/venv
    
    log "Step 3: Installing pip dependencies..."
    /opt/ioc-parser/venv/bin/pip install --no-cache-dir --upgrade pip
    
    # Note: pdfminer.six is the active Python 3 fork of pdfminer
    /opt/ioc-parser/venv/bin/pip install --no-cache-dir ioc_parser PyPDF2 pdfminer.six beautifulsoup4 requests

    log "Step 4: Establishing System PATH Bindings..."
    # Create a persistent wrapper script in the global bin path
    cat << 'EOF' > /usr/local/bin/ioc-parser
#!/usr/bin/env bash
# Wrapper to execute the isolated venv python module
exec /opt/ioc-parser/venv/bin/python3 -m ioc_parser "$@"
EOF
    chmod +x /usr/local/bin/ioc-parser

    log "Step 5: Triggering UI integration..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "${SCRIPT_DIR}/configure_ui.sh" ]; then
        bash "${SCRIPT_DIR}/configure_ui.sh"
    fi

    log "IOC Parser installation complete."
}

main "$@"
