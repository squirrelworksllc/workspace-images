# syntax=docker/dockerfile:1.7

# ----------------------------- DESCRIPTION -----------------------------
# BitCurator5 Kasm image.
# Built on top of squirrelworksllc/ubuntu-noble-core, then runs BitCurator5
# installer scripts.
#
# Provides:
#   - lint target (hadolint + shellcheck)
#   - develop target
#   - production target (default)
#
# IMPORTANT:
# Build context is repo root.
#   Lint: docker build --target lint -f images/bitcurator5/Dockerfile .
#   Prod: docker build -t squirrelworksllc/bitcurator5:1.18.0 -f images/bitcurator5/Dockerfile .
#   Dev : docker build --target develop -t squirrelworksllc/bitcurator5:develop -f images/bitcurator5/Dockerfile .
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
RUN bash /src/tools/ci/lint-dockerfile.sh /src/images/bitcurator5/Dockerfile
RUN bash /src/tools/ci/lint-shell.sh

USER 1000

# ############################################################################
# ------------------------------ BUILD TARGET ------------------------------ #
# ############################################################################
FROM base AS build
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Move validation script to base tools folder.
RUN mkdir -p /dockerstartup/tools
COPY ./src/tools/runtime/runtime_validation.sh /dockerstartup/tools/runtime_validation.sh
RUN chmod 0755 /dockerstartup/tools/runtime_validation.sh

# Run Installs
ENV INST_SCRIPTS="/ubuntu/install/tools/install_tools.sh \
/ubuntu/install/bitcurator/install_bitcurator5.sh \
/ubuntu/install/common/01_cleanup.sh"

COPY ./src/ubuntu/install/ ./__context_check__/ubuntu_install/
RUN rm -rf ./__context_check__

COPY ./src/ubuntu/ ${INST_DIR}/ubuntu/

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
