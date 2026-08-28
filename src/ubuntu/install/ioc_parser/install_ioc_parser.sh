#!/usr/bin/env bash
###############################################################################
# install_ioc_parser.sh
# Purpose: Installs an IOC-extraction tool in an isolated venv, exposed as the
#          `ioc-parser` command.
#
# NOTE: the original PyPI "ioc_parser" is Python 2 / unmaintained and does not
# run on Noble's Python 3. We back the same command with iocextract
# (maintained, py3), plus pdfminer.six for PDF input.
###############################################################################
set -euo pipefail
: "${INST_DIR:=/dockerstartup/install}"
source "${INST_DIR}/ubuntu/install/common/00_apt_helper.sh"

log() { echo "[IOC-PARSER-INSTALL] $*"; }

VENV="/opt/ioc-parser/venv"

main() {
    log "======= Installing IOC Parser (iocextract) ======="

    apt_update_if_needed
    apt_install python3-venv zenity

    log "Creating the isolated venv..."
    mkdir -p /opt/ioc-parser
    python3 -m venv "${VENV}"
    "${VENV}/bin/pip" install --no-cache-dir --upgrade pip
    "${VENV}/bin/pip" install --no-cache-dir iocextract "pdfminer.six"

    log "Installing the ioc-parser wrapper..."
    cat > /usr/local/bin/ioc-parser <<'EOF'
#!/usr/bin/env bash
# ioc-parser: pull indicators of compromise (URLs, IPs, domains, emails, file
# hashes) out of a document or stdin, using iocextract. Defanged IOCs
# ("hxxp://", "1[.]2[.]3[.]4") are re-fanged automatically.
set -uo pipefail
VENV=/opt/ioc-parser/venv
export PATH="${VENV}/bin:${PATH}"

_extract() {
    case "${1,,}" in
        *.pdf) pdf2txt.py "$1" 2>/dev/null | iocextract --refang ;;
        *)     iocextract --refang --input "$1" ;;
    esac
}

if [ "$#" -ge 1 ]; then
    for f in "$@"; do
        if [ -f "$f" ]; then
            echo "== ${f} =="
            _extract "$f"
        else
            echo "not a file: ${f}" >&2
        fi
    done
    exit 0
fi

# No args: interactive when launched from the menu, else read stdin.
if [ -t 0 ]; then
    f=""
    if command -v zenity >/dev/null 2>&1 && [ -n "${DISPLAY:-}" ]; then
        f="$(zenity --file-selection --title='IOC Parser - choose a document' 2>/dev/null || true)"
    fi
    [ -n "$f" ] || read -rp "Path to a document (txt / pdf / html): " f
    if [ ! -f "$f" ]; then
        echo "No readable file."
        read -rp "Press Enter to close..." _
        exit 1
    fi
    echo "== ${f} =="
    _extract "$f"
    echo
    read -rp "Press Enter to close..." _
else
    iocextract --refang
fi
EOF
    chmod 0755 /usr/local/bin/ioc-parser

    log "Step 5: Triggering UI integration..."
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if [ -f "${SCRIPT_DIR}/configure_ui.sh" ]; then
        bash "${SCRIPT_DIR}/configure_ui.sh"
    fi

    log "IOC Parser installation complete."
}

main "$@"
