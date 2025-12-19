#WIP - NOT WORKING

# syntax=docker/dockerfile:1.7
# ----------------------------- DESCRIPTION -----------------------------
# Custom REMnux-based Kasm image.
# NOTE: This Dockerfile intentionally uses a focal desktop base (per your policy),
# and the /ubuntu/install/remnux/install_remnux.sh script handles the actual REMnux install.
#
# Provides:
#   - lint target (hadolint + shellcheck)
#   - develop target
#   - production target (default)
#
# IMPORTANT:
# This Dockerfile assumes the BUILD CONTEXT is the REPO ROOT.
# Examples:
#   Lint: docker build --target lint -f images/remnux/Dockerfile .
#   Prod: docker build -t squirrelworksllc/remnux:latest -f images/remnux/Dockerfile .
#   Dev : docker build --target develop -t squirrelworksllc/remnux:develop -f images/remnux/Dockerfile .
# ----------------------------------------------------------------------

# REMnux base (older Kasm focal desktop image)
ARG BASE_IMAGE="ubuntu-focal-desktop"
ARG BASE_TAG="1.16.1-rolling-weekly"

# ############################################################################
# -------------------------------- BASE ----------------------------------- #
# ############################################################################
FROM kasmweb/${BASE_IMAGE}:${BASE_TAG} AS base

USER root

ENV HOME=/home/kasm-default-profile
ENV STARTUPDIR=/dockerstartup
WORKDIR ${HOME}

ENV DEBIAN_FRONTEND=noninteractive \
    SKIP_CLEAN=true \
    KASM_RX_HOME=${STARTUPDIR}/kasmrx \
    DONT_PROMPT_WSL_INSTALL="No_Prompt_please" \
    INST_DIR=${STARTUPDIR}/install


# ############################################################################
# ------------------------------ LINT TARGET ------------------------------- #
# ############################################################################
FROM base AS lint

# install hadolint + shellcheck here...
WORKDIR /src
COPY . /src

# installs hadolint + shellcheck
RUN bash /src/tools/ci/lint_installers.sh

# Dockerfile lint (centralized policy)
RUN bash /src/tools/ci/lint-dockerfile.sh /src/images/remnux/Dockerfile

# Shell script lint (centralized policy)
RUN bash /src/tools/ci/lint-shell.sh

USER 1000

# ############################################################################
# ------------------------------ BUILD TARGET ------------------------------ #
# ############################################################################
FROM base AS build

# Install script list
ENV INST_SCRIPTS="/ubuntu/install/tools/install_tools.sh \
/ubuntu/install/remnux/install_remnux.sh \
/ubuntu/install/common/01_cleanup.sh"

# Guard: fail fast if build context isn't repo root (COPY fails if missing)
COPY ./src/ubuntu/install/ ./__context_check__/ubuntu_install/
RUN rm -rf ./__context_check__

# Copy just ubuntu/ into /dockerstartup/install/ubuntu/
COPY ./src/ubuntu/ ${INST_DIR}/ubuntu/

# Run installations
RUN set -eux; \
    apt-get update; \
    for SCRIPT in ${INST_SCRIPTS}; do \
      echo ">>> Running ${SCRIPT}"; \
      bash "${INST_DIR}${SCRIPT}" || { echo "FAILED: ${SCRIPT}"; exit 1; }; \
    done; \
    "${STARTUPDIR}/set_user_permission.sh" "${HOME}"; \
    rm -f /etc/X11/xinit/Xclients; \
    chown 1000:0 "${HOME}"; \
    mkdir -p /home/kasm-user; \
    chown -R 1000:0 /home/kasm-user; \
    rm -rf "${INST_DIR}"

# Userspace Runtime
ENV HOME=/home/kasm-user
WORKDIR ${HOME}
USER 1000

CMD ["--tail-log"]


# ############################################################################
# ------------------------------- DEVELOP IMAGE ---------------------------- #
# ############################################################################
FROM build AS develop
ENV DEBUG=true


# ############################################################################
# ----------------------------- PRODUCTION IMAGE --------------------------- #
# ############################################################################
FROM build AS production
ENV DEBUG=false
