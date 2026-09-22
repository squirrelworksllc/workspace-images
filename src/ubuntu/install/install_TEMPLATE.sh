#!/usr/bin/env bash
###############################################################################
# install_APPNAME.sh
#
# Debian-based only (Debian / Ubuntu). Called non-interactively from a
# Dockerfile to install [APP NAME] into a Kasm-enabled Ubuntu image.
#
# Responsibilities:
#   - Install [APP NAME] (apt / 3rd-party repo / .deb / tarball / venv)
#   - Register the Applications-menu entry (usually the package does this)
#   - Delegate the Desktop-icon decision to configure_ui.sh via the
#     desktop_icon helper (per-app <APPNAME>_DESKTOP_ICON toggle)
#
# 03_scaffold.sh gives us: log(), require_root, require_arch[_hard], install_deb,
# add_apt_repo, run_configure_ui, plus everything from 00_apt_helper.sh and
# 10_desktop_icon.sh.
###############################################################################
set -euo pipefail
LOG_TAG="APPNAME"
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/03_scaffold.sh"

main() {
    log "======= Installing APPNAME ======="

    # require_root                 # uncomment if the module must run as uid 0
    # require_arch amd64           # skip cleanly on other arches (exit 0)
    # require_arch_hard amd64      # OR fail the build on other arches (exit 1)

    apt_update_if_needed

    # --- pick ONE install path -------------------------------------------

    # a) straight from the distro:
    # apt_install APPNAME

    # b) third-party apt repo:
    # add_apt_repo appname \
    #     "https://vendor.example/key.asc" \
    #     "https://vendor.example/apt" "stable" "main"
    # apt_install appname

    # c) a .deb by URL (or local path):
    # install_deb "https://vendor.example/appname_amd64.deb"

    # d) tarball / venv / GitHub release: do it inline here.

    # --- hand off to configure_ui.sh (menu tweaks + desktop_icon) --------
    run_configure_ui

    log "APPNAME install complete."
}

main "$@"
