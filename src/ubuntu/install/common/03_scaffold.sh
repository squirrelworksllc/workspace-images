#!/usr/bin/env bash
###############################################################################
# 03_scaffold.sh   (sourced - the standard prelude for an install_*.sh module)
#
# One source line pulls in the apt helper + the desktop-icon helper and adds
# the scaffolding every module was hand-rolling:
#
#   #!/usr/bin/env bash
#   set -euo pipefail
#   LOG_TAG="SIGNAL"
#   : "${INST_DIR:=/dockerstartup/install}"
#   source "${INST_DIR}/ubuntu/install/common/03_scaffold.sh"
#
# Provides (on top of 00_apt_helper.sh / 10_desktop_icon.sh):
#   log <msg>                       - "[<LOG_TAG>] <msg>"  (LOG_TAG default: MODULE)
#   require_root                    - exit 1 if not uid 0
#   require_arch <arch>             - exit 0 (skip) if dpkg arch != <arch>
#   require_arch_hard <arch>        - exit 1 if dpkg arch != <arch>
#   run_configure_ui               - run the caller's adjacent configure_ui.sh
#   install_deb <url|path>          - fetch (if URL) + apt-get install + clean up
#   add_apt_key  <name> <key-url>   - dearmor a key into /etc/apt/keyrings/<name>.gpg
#   add_apt_repo <name> <key-url> <uris> <suites> [components] [arch]
#                                  - key + a DEB822 .sources file, then refresh
###############################################################################

# --- pull in the sibling helpers -------------------------------------------
_sqw_common_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=/dev/null
source "${_sqw_common_dir}/00_apt_helper.sh"
# shellcheck source=/dev/null
source "${_sqw_common_dir}/10_desktop_icon.sh"

# --- logging (00_apt_helper defines a generic log(); override with a tag) ---
log() { echo "[${LOG_TAG:-MODULE}] $*"; }

# --- guards ---------------------------------------------------------------
require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log "ERROR: must run as root" >&2
        exit 1
    fi
}

require_arch() {
    local want="$1" have
    have="$(dpkg --print-architecture)"
    if [ "$have" != "$want" ]; then
        log "${want}-only; skipping on ${have}."
        exit 0
    fi
}

require_arch_hard() {
    local want="$1" have
    have="$(dpkg --print-architecture)"
    if [ "$have" != "$want" ]; then
        log "ERROR: ${want}-only; refusing to build on ${have}." >&2
        exit 1
    fi
}

# --- run the module's own configure_ui.sh, if it has one ------------------
run_configure_ui() {
    local dir
    dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
    if [ -f "${dir}/configure_ui.sh" ]; then
        log "Applying UI configuration..."
        bash "${dir}/configure_ui.sh"
    fi
}

# --- install a .deb from a URL or a local path --------------------------
install_deb() {
    local src="$1" tmp
    if [[ "$src" =~ ^https?:// ]]; then
        tmp="$(mktemp --suffix=.deb)"
        log "Downloading ${src}"
        curl -fL --retry 3 --retry-delay 2 -o "$tmp" "$src"
        apt-get install -y "$tmp"
        rm -f "$tmp"
    else
        apt-get install -y "$src"
    fi
}

# --- third-party apt repository (keyring + DEB822 .sources) --------------
add_apt_key() {
    local name="$1" url="$2"
    install -d -m 0755 /etc/apt/keyrings
    curl -fsSL "$url" | gpg --batch --yes --dearmor -o "/etc/apt/keyrings/${name}.gpg"
    chmod 0644 "/etc/apt/keyrings/${name}.gpg"
}

add_apt_repo() {
    local name="$1" key_url="$2" uris="$3" suites="$4"
    local comps="${5:-main}" arch="${6:-$(dpkg --print-architecture)}"

    log "Adding apt repo '${name}' (${uris} ${suites})"
    add_apt_key "$name" "$key_url"

    cat > "/etc/apt/sources.list.d/${name}.sources" <<EOF
Types: deb
URIs: ${uris}
Suites: ${suites}
Components: ${comps}
Architectures: ${arch}
Signed-By: /etc/apt/keyrings/${name}.gpg
EOF

    apt_refresh_after_repo_change
}
