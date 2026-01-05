# syntax=docker/dockerfile:1.7

# ----------------------------- DESCRIPTION -----------------------------
# REMnux (Kasm-compatible) for Ubuntu Noble.
#
# Built on the SquirrelWorks Ubuntu Noble core image and extended with the
# REMnux CLI installer (addon style) via /ubuntu/install/remnux/install_remnux.sh.
#
# Provides:
#   - lint target (hadolint + shellcheck)
#   - develop target
#   - production target (default)
#
# IMPORTANT:
# This Dockerfile assumes the BUILD CONTEXT is the REPO ROOT.
# Example builds:
#   Lint: docker build --target lint -f images/remnux/Dockerfile .
#   Prod: docker build -t squirrelworksllc/remnux:1.18.0 -f images/remnux/Dockerfile .
#   Dev : docker build --target develop -t squirrelworksllc/remnux:develop -f images/remnux/Dockerfile .
# ----------------------------------------------------------------------

ARG BASE_IMAGE="squirrelworksllc/ubuntu-noble-core"
ARG BASE_TAG="1.18.0"

# ############################################################################
# -------------------------------- BASE ----------------------------------- #
# ############################################################################
FROM ${BASE_IMAGE}:${BASE_TAG} AS base
USER root

ENV HOME=/home/kasm-default-profile \
    STARTUPDIR=/dockerstartup \
    DEBIAN_FRONTEND=noninteractive \
    SKIP_CLEAN=true \
    KASM_RX_HOME=/dockerstartup/kasmrx \
    DONT_PROMPT_WSL_INSTALL="No_Prompt_please" \
    INST_DIR=/dockerstartup/install

WORKDIR ${HOME}

# ############################################################################
# ------------------------------ LINT TARGET ------------------------------- #
# ############################################################################
FROM base AS lint
WORKDIR /src
COPY . /src

RUN bash /src/tools/ci/lint_installers.sh
RUN bash /src/tools/ci/lint-dockerfile.sh /src/images/remnux/Dockerfile
RUN bash /src/tools/ci/lint-shell.sh

USER 1000

# ############################################################################
# ------------------------------ BUILD TARGET ------------------------------ #
# ############################################################################
FROM base AS build
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Guard: fail fast if build context isn't repo root (COPY fails if missing)
COPY ./src/ubuntu/install/ ./__context_check__/ubuntu_install/
RUN rm -rf ./__context_check__

# Copy just ubuntu/ into /dockerstartup/install/ubuntu/
COPY ./src/ubuntu/ ${INST_DIR}/ubuntu/

# Move validation script to base tools folder.
RUN mkdir -p /dockerstartup/tools
COPY ./src/tools/runtime/runtime_validation.sh /dockerstartup/tools/runtime_validation.sh
RUN chmod 0755 /dockerstartup/tools/runtime_validation.sh

# Install script list (keep intentionally small)
ENV INST_SCRIPTS="/ubuntu/install/tools/install_tools.sh \
/ubuntu/install/remnux/install_remnux.sh \
/ubuntu/install/common/01_cleanup.sh"

RUN set -eux; \
    apt-get update; \
    for SCRIPT in ${INST_SCRIPTS}; do \
      echo ">>> Running ${SCRIPT}"; \
      bash "${INST_DIR}${SCRIPT}" || { echo "FAILED: ${SCRIPT}"; exit 1; }; \
    done; \
    "${STARTUPDIR}/set_user_permission.sh" "${HOME}"; \
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
# ------------------------------- DEVELOP --------------------------------- #
# ############################################################################
FROM build AS develop
ENV DEBUG=true

# ############################################################################
# ----------------------------- PRODUCTION -------------------------------- #
# ############################################################################
FROM build AS production
ENV DEBUG=false
