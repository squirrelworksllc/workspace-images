#!/usr/bin/env bash
# Interactive builder for repo images (always repo-root context)
#
# This script provides a menu-driven way to build the Docker images defined
# in .vscode/images.json. It handles different build modes (lint, dev, prod)
# and automatically manages dependencies between local images for dev builds.

set -euo pipefail
export DOCKER_BUILDKIT=1

# Source the modularized scripts
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/scripts/docker-context-check.sh"
source "${SCRIPT_DIR}/scripts/docker-build.sh"

################################################################################
# Argument Parsing
################################################################################

ARG_BG_RUNNING="false"
ARG_MODE=""
ARG_IMAGE=""
ARG_APT_DEBUG=""
ARG_AUTO_BUILD_BASE=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --bg-running) ARG_BG_RUNNING="true"; shift ;;
    --mode) ARG_MODE="$2"; shift 2 ;;
    --image) ARG_IMAGE="$2"; shift 2 ;;
    --apt-debug) ARG_APT_DEBUG="$2"; shift 2 ;;
    --auto-build-base) ARG_AUTO_BUILD_BASE="$2"; shift 2 ;;
    *) shift ;;
  esac
done

################################################################################
# Script Configuration & Globals
################################################################################

readonly CONFIG_FILE=".vscode/images.json"
readonly REPO_ROOT="$(git rev-parse --show-toplevel)"
readonly CURRENT_CONTEXT="$(get_docker_context)"

# These variables are populated by the prompt/parse functions
BUILD_MODE=""
IMAGE_KEY=""
IMAGE_CONFIG_JSON=""

DOCKERFILE=""
REPO=""
PROD_TAG=""
DEV_TAG=""
DEV_TARGET=""
LINT_TARGET=""

################################################################################
# Logging and Utility Functions
################################################################################

# Prints an error message and exits.
# Usage: fail "Something went wrong"
fail() {
  echo >&2 ""
  echo >&2 "ERROR: $*"
  exit 1
}

# Prints an informational message.
# Usage: log_info "Starting build..."
log_info() {
  echo "[INFO] $*"
}

# Checks for required command-line tools.
check_dependencies() {
  command -v jq >/dev/null || fail "jq is required but not found in PATH."
  # Check for jq >= 1.5 which supports the '//' and 'as' operators
  local jq_version
  jq_version="$(jq --version | sed 's/jq-//')"
  if ! printf '%s
%s
' "1.5" "$jq_version" | sort -V -C 2>/dev/null; then
    fail "jq version 1.5 or newer is required for this script. You have ${jq_version}. Please upgrade jq."
  fi
  command -v git >/dev/null || fail "git is required but not found in PATH."
  [[ -n "${REPO_ROOT}" ]] || fail "Could not determine repository root. Must be run inside a git repo."
  [[ -f "${CONFIG_FILE}" ]] || fail "Config file not found: ${CONFIG_FILE}"
}

################################################################################
# User Interaction and Configuration Parsing
################################################################################

# Prompts the user to select a build mode (lint, prod, or dev).
prompt_for_mode() {
  if [[ -n "$ARG_MODE" ]]; then
    BUILD_MODE="$ARG_MODE"
    return
  fi

  echo ""
  read -r -p "Select mode [lint/prod/dev/clean] (default: lint): " mode_in
  BUILD_MODE="${mode_in:-lint}"

  case "$BUILD_MODE" in
    lint|prod|production|dev|develop|clean) ;;
    *) fail "Unknown mode: '$BUILD_MODE'. Use lint, prod, or dev." ;;
  esac
}

# Prompts the user to select which image to build from images.json.
prompt_for_image() {
  if [[ -n "$ARG_IMAGE" ]]; then
    IMAGE_KEY="$ARG_IMAGE"
    return
  fi

  mapfile -t image_keys < <(jq -r '.images[].key' "$CONFIG_FILE")
  [[ "${#image_keys[@]}" -gt 0 ]] || fail "No images found in $CONFIG_FILE"

  echo ""
  echo "Select image:"
  select key in "${image_keys[@]}"; do
    if [[ -n "$key" ]]; then
      IMAGE_KEY="$key"
      break
    fi
    echo "Invalid selection."
  done
}

# Parses the selected image's configuration from images.json into global variables.
parse_image_config() {
  IMAGE_CONFIG_JSON="$(jq -r --arg key "$IMAGE_KEY" '.images[] | select(.key==$key)' "$CONFIG_FILE")"
  [[ -n "$IMAGE_CONFIG_JSON" ]] || fail "Image key '$IMAGE_KEY' not found in $CONFIG_FILE"

  DOCKERFILE="$(jq -r '.dockerfile' <<<"$IMAGE_CONFIG_JSON")"
  REPO="$(jq -r '.repo' <<<"$IMAGE_CONFIG_JSON")"
  PROD_TAG="$(jq -r '(.prodTags // [])[0] // empty' <<<"$IMAGE_CONFIG_JSON")"
  DEV_TAG="$(jq -r '(.devTags // ["develop"])[0]' <<<"$IMAGE_CONFIG_JSON")"
  DEV_TARGET="$(jq -r '.devTarget // empty' <<<"$IMAGE_CONFIG_JSON")"
  LINT_TARGET="$(jq -r '.lintTarget // "lint"' <<<"$IMAGE_CONFIG_JSON")"

  [[ -f "$DOCKERFILE" ]] || fail "Dockerfile not found: $DOCKERFILE"
}

################################################################################
# Main Execution
################################################################################

main() {
  cd "${REPO_ROOT}"
  check_dependencies

  prompt_for_mode

  if [[ "$BUILD_MODE" == "clean" ]]; then
    run_clean
    log_info "Build script finished."
    exit 0
  fi

  prompt_for_image
  parse_image_config

  # Pre-prompt for dev build options before potentially going to background
  if [[ "$ARG_BG_RUNNING" != "true" && ("$BUILD_MODE" == "dev" || "$BUILD_MODE" == "develop") ]]; then
    if grep -q 'ARG APT_DEBUG' "$DOCKERFILE"; then
      read -r -p "Enable APT debug output for this DEV build? [y/N]: " ans
      ARG_APT_DEBUG="${ans:-n}"
    fi

    local internal_base_repo
    internal_base_repo="$(awk -F'"' '/ARG BASE_IMAGE="squirrelworksllc\// {print $2}' "$DOCKERFILE" | head -n1)"
    if [[ -n "$internal_base_repo" ]]; then
      local required_base_repo_full="docker.io/${internal_base_repo}"
      local required_base_image_full="${required_base_repo_full}:develop"
      if ! docker --context "$CURRENT_CONTEXT" image inspect "$required_base_image_full" &>/dev/null; then
        echo ""
        log_info "Required base image '${required_base_image_full}' is not available locally."
        read -r -p "Would you like to build it now? [Y/n] " ans_build_base
        ARG_AUTO_BUILD_BASE="${ans_build_base:-y}"
        if [[ "${ARG_AUTO_BUILD_BASE,,}" == "n" ]]; then
           fail "Build cancelled. Please build '${required_base_image_full}' manually and retry."
        fi
      fi
    fi
  fi

  # Call the context check logic from docker-context-check.sh
  check_and_background "$CURRENT_CONTEXT" "$ARG_BG_RUNNING" "$BUILD_MODE" "$IMAGE_KEY" "$ARG_APT_DEBUG" "$ARG_AUTO_BUILD_BASE" "${SCRIPT_DIR}/$(basename "${BASH_SOURCE[0]}")"

  # --- SQUIRRELWORKS ARCHITECT LOGIC ---
  echo "🔨 Initializing build sequence on: $CURRENT_CONTEXT"

  echo ""
  log_info "Selected Image: ${IMAGE_KEY}"
  log_info "Mode:           ${BUILD_MODE}"
  log_info "Dockerfile:     ${DOCKERFILE}"
  log_info "Context:        ${REPO_ROOT}"
  echo ""

  case "$BUILD_MODE" in
    dev|develop)
      run_dev_build
      ;;
    lint)
      run_lint_build
      ;;
    prod|production)
      run_prod_build
      ;;
  esac

  echo ""
  log_info "Build script finished."
}

# Run the main function
main
