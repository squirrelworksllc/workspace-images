#!/usr/bin/env bash
###############################################################################
# install_slack.sh
# Purpose: Installs Slack Desktop from the PackageCloud apt repo.
###############################################################################
set -euo pipefail
LOG_TAG="SLACK-INSTALL"
: "${INST_DIR:=/dockerstartup/install}"
# shellcheck source=/dev/null
source "${INST_DIR}/ubuntu/install/common/03_scaffold.sh"

main() {
    log "======= Installing Slack Desktop ======="
    require_arch amd64

    apt_update_if_needed
    # PackageCloud uses "jessie" as their generic Debian suite name.
    add_apt_repo slack \
        "https://packagecloud.io/slacktechnologies/slack/gpgkey" \
        "https://packagecloud.io/slacktechnologies/slack/debian/" "jessie" "main"
    apt_install slack-desktop

    run_configure_ui
    log "Slack installation complete!"
}

main "$@"
