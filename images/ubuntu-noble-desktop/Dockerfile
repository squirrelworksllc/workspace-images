# syntax=docker/dockerfile:1.7

ARG BASE_TAG="1.18.0-rolling-weekly"
ARG BASE_IMAGE="core-ubuntu-noble"

FROM kasmweb/${BASE_IMAGE}:${BASE_TAG} AS base
USER root

ENV HOME=/home/kasm-default-profile \
    STARTUPDIR=/dockerstartup \
    DEBIAN_FRONTEND=noninteractive \
    SKIP_CLEAN=true \
    KASM_RX_HOME=/dockerstartup/kasmrx \
    DONT_PROMPT_WSL_INSTALL="No_Prompt_please" \
    INST_DIR=/dockerstartup/install \
    INSTALL_CHROME=true

WORKDIR ${HOME}

# ------------------------------ LINT TARGET ------------------------------
FROM base AS lint
WORKDIR /src
COPY . /src
RUN bash /src/tools/ci/lint_installers.sh
RUN bash /src/tools/ci/lint-dockerfile.sh /src/images/ubuntu-noble-desktop/Dockerfile
RUN bash /src/tools/ci/lint-shell.sh
USER 1000

# ------------------------------ BUILD TARGET -----------------------------
FROM base AS build
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# NEW STRUCTURE: installers live at repo-root ./ubuntu/install/**
# Copy just ubuntu/ into /dockerstartup/install/ubuntu/
COPY ./src/ubuntu/ ${INST_DIR}/ubuntu/

RUN set -eux; \
    apt-get update; \
    SCRIPTS=( \
      "/ubuntu/install/tools/install_tools.sh" \
      "/ubuntu/install/chrome/install_chrome.sh" \
      "/ubuntu/install/firefox/install_firefox.sh" \
      "/ubuntu/install/thunderbird/install_thunderbird.sh" \
      "/ubuntu/install/vs_code/install_vs_code.sh" \
      "/ubuntu/install/remmina/install_remmina.sh" \
      "/ubuntu/install/libre_office/install_libre_office.sh" \
      "/ubuntu/install/signal/install_signal.sh" \
      "/ubuntu/install/gimp/install_gimp.sh" \
      "/ubuntu/install/ansible/install_ansible.sh" \
      "/ubuntu/install/slack/install_slack.sh" \
      "/ubuntu/install/discord/install_discord.sh" \
      "/ubuntu/install/teams/install_teams.sh" \
      "/ubuntu/install/obsidian/install_obsidian.sh" \
      "/ubuntu/install/infosec_yara/install_infosec_yara.sh" \
      "/ubuntu/install/tesseract_ocr/install_tesseract_ocr.sh" \
      "/ubuntu/install/tor_browser/install_tor_browser.sh" \
      "/ubuntu/install/torboost/install_torboost.sh" \
      "/ubuntu/install/common/01_cleanup.sh" \
    ); \
    for SCRIPT in "${SCRIPTS[@]}"; do \
      echo ">>> Running ${SCRIPT}"; \
      bash "${INST_DIR}${SCRIPT}" || { echo "FAILED: ${SCRIPT}"; exit 1; }; \
    done; \
    "${STARTUPDIR}/set_user_permission.sh" "${HOME}"; \
    rm -f /etc/X11/xinit/Xclients; \
    chown 1000:0 "${HOME}"; \
    mkdir -p /home/kasm-user; \
    chown -R 1000:0 /home/kasm-user; \
    rm -rf "${INST_DIR}"

ENV HOME=/home/kasm-user
WORKDIR ${HOME}
USER 1000
CMD ["--tail-log"]

FROM build AS develop
ENV DEBUG=true

FROM build AS production
ENV DEBUG=false