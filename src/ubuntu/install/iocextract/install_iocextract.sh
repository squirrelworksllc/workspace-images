#!/usr/bin/env bash
###############################################################################
# install_iocextract.sh
#
# Purpose: Installs iocextract (InQuest, Python 3) into an isolated venv,
#          exposed as the `iocextract` command plus a terminal launcher.
#
# Background: this module replaces the old "ioc_parser" one. The PyPI
# `ioc_parser` package is Python 2 / abandoned (last release 2016) and does not
# run on Ubuntu Noble's Python 3. iocextract does the same job - pulling URLs,
# IPs, domains, e-mail addresses, file hashes and YARA rules out of a document
# or stream, including "defanged" indicators (hxxp://, 1[.]2[.]3[.]4) - and is
# still shipping releases.
#
#   Project: https://github.com/InQuest/iocextract
#   Docs:    https://inquest.readthedocs.io/projects/iocextract/en/latest/
#
# There is no upstream GUI for iocextract; the launcher runs it in a terminal
# with a file picker.
###############################################################################
set -euo pipefail
LOG_TAG="IOCEXTRACT-INSTALL"
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/03_scaffold.sh"

VENV="/opt/iocextract/venv"

main() {
    log "======= Installing iocextract ======="

    apt_update_if_needed
    apt_install python3-venv zenity

    log "Creating the isolated venv at ${VENV}..."
    mkdir -p /opt/iocextract
    python3 -m venv "${VENV}"
    "${VENV}/bin/pip" install --no-cache-dir --upgrade pip
    # pdfminer.six lets the wrapper accept PDF input as well as plain text.
    "${VENV}/bin/pip" install --no-cache-dir iocextract "pdfminer.six"

    log "Installing the iocextract wrapper..."
    cat > /usr/local/bin/iocextract <<'EOF'
#!/usr/bin/env bash
# iocextract: pull indicators of compromise (URLs, IPs, domains, e-mail
# addresses, file hashes, YARA rules) out of a document or stdin. Defanged
# indicators (hxxp://, 1[.]2[.]3[.]4) are re-fanged automatically.
#
#   iocextract report.pdf                scan a file
#   iocextract notes.txt --extract-urls  scan a file, pass extra flags through
#   cat sample | iocextract              scan stdin
#   iocextract                           (from the menu) pick a file, show output
#
# See: https://inquest.readthedocs.io/projects/iocextract/en/latest/
set -uo pipefail
VENV=/opt/iocextract/venv
BIN="${VENV}/bin/iocextract"
export PATH="${VENV}/bin:${PATH}"

_scan() {
    local f="$1"; shift
    case "${f,,}" in
        *.pdf) pdf2txt.py "$f" 2>/dev/null | "$BIN" --refang "$@" ;;
        *)     "$BIN" --refang --input "$f" "$@" ;;
    esac
}

# First arg is a readable file -> scan it (remaining args pass through).
if [ "$#" -ge 1 ] && [ -f "$1" ]; then
    _file="$1"; shift
    _scan "$_file" "$@"
    exit $?
fi

# Extra flags but no file, or piped input -> straight through.
if [ "$#" -ge 1 ] || [ ! -t 0 ]; then
    exec "$BIN" --refang "$@"
fi

# Interactive (launched from the menu): pick a file.
_file=""
if command -v zenity >/dev/null 2>&1 && [ -n "${DISPLAY:-}" ]; then
    _file="$(zenity --file-selection --title='iocextract - choose a document' 2>/dev/null || true)"
fi
[ -n "$_file" ] || read -rp "Path to a document (txt / pdf / html): " _file
if [ ! -f "$_file" ]; then
    echo "No readable file."
    read -rp "Press Enter to close..." _
    exit 1
fi
echo "== ${_file} =="
_scan "$_file"
echo
read -rp "Press Enter to close..." _
EOF
    chmod 0755 /usr/local/bin/iocextract

    log "Step 5: Triggering UI integration..."
    run_configure_ui

    log "iocextract installation complete."
}

main "$@"
