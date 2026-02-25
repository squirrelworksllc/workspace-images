#!/usr/bin/env bash
# Interactive builder for repo images (always repo-root context)
#
# This script provides a menu-driven way to build the Docker images defined
# in .vscode/images.json. It handles different build modes (lint, dev, prod)
# and automatically manages dependencies between local images for dev builds.

set -euo pipefail
export DOCKER_BUILDKIT=1

################################################################################
# Script Configuration & Globals
################################################################################

readonly CONFIG_FILE=".vscode/images.json"
readonly REPO_ROOT="$(git rev-parse --show-toplevel)"

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
  command -v git >/dev/null || fail "git is required but not found in PATH."
  [[ -n "${REPO_ROOT}" ]] || fail "Could not determine repository root. Must be run inside a git repo."
  [[ -f "${CONFIG_FILE}" ]] || fail "Config file not found: ${CONFIG_FILE}"
}

################################################################################
# User Interaction and Configuration Parsing
################################################################################

# Prompts the user to select a build mode (lint, prod, or dev).
prompt_for_mode() {
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
# Build Logic Functions
################################################################################

# --- LINT BUILD ---
run_lint_build() {
  log_info "Running LINT build for '${IMAGE_KEY}' (target=${LINT_TARGET})"
  docker build \
    --progress=plain \
    --no-cache \
    --target "$LINT_TARGET" \
    -f "$DOCKERFILE" \
    "$REPO_ROOT"
}

# --- CLEAN DEV IMAGES ---
run_clean() {
  log_info "Cleaning up local 'develop' images defined in ${CONFIG_FILE}..."
  local images_to_clean
  mapfile -t images_to_clean < <(jq -r '.images[] | "docker.io/\(.repo):\(.devTag // "develop")"' "$CONFIG_FILE")

  if [[ "${#images_to_clean[@]}" -eq 0 ]]; then
    log_info "No images to clean."
    return
  fi

  echo "The following images will be removed if they exist locally:"
  printf " - %s\n" "${images_to_clean[@]}"
  echo ""
  read -r -p "Continue? [Y/n] " ans
  [[ "${ans,,}" == "n" ]] && fail "Clean operation cancelled."

  docker image rm -f "${images_to_clean[@]}"
}

# --- PRODUCTION BUILD ---
run_prod_build() {
  [[ -n "$PROD_TAG" ]] || fail "prodTags array is empty or not set for key '$IMAGE_KEY' in $CONFIG_FILE"
  log_info "Building PROD: ${REPO}:${PROD_TAG}"

  docker build \
    --progress=plain \
    -f "$DOCKERFILE" \
    -t "${REPO}:${PROD_TAG}" \
    "$REPO_ROOT"
}

# --- DEVELOPMENT BUILD ---
run_dev_build() {
  [[ -n "$DEV_TARGET" ]] || fail "devTarget is not set for key '$IMAGE_KEY' in $CONFIG_FILE"
  log_info "Preparing DEV build for ${IMAGE_KEY}"

  local build_args=()

  # Ask user if they want to enable APT debug output, if supported by the Dockerfile.
  if grep -q 'ARG APT_DEBUG' "$DOCKERFILE"; then
    read -r -p "Enable APT debug output for this DEV build? [y/N]: " ans
    [[ "${ans,,}" == "y" || "${ans,,}" == "yes" ]] && build_args+=("--build-arg" "APT_DEBUG=true")
  fi

  # --- Handle Internal Base Image Dependencies ---
  # This is the core logic for making dev builds work on ARM64/Snapdragon.
  # It detects if the Dockerfile uses another image from this repo (e.g., remnux using ubuntu-noble-core).
  local internal_base_repo
  internal_base_repo="$(awk -F'"' '/ARG BASE_IMAGE="squirrelworksllc\// {print $2}' "$DOCKERFILE" | head -n1)"

  if [[ -n "$internal_base_repo" ]]; then
    log_info "Detected internal base image: ${internal_base_repo}"

    # For dev builds, we MUST use the 'develop' tag of the base image.
    # We also normalize the repo name to include 'docker.io/' to ensure
    # Docker's buildkit finds the local image instead of trying to pull from the registry.
    local required_base_repo_full="docker.io/${internal_base_repo}"
    local required_base_image_full="${required_base_repo_full}:develop"

    log_info "This build requires the local base image: '${required_base_image_full}'"

    # Check if the required base image exists locally for the current architecture.
    if ! docker image inspect "$required_base_image_full" &>/dev/null; then
      echo ""
      log_info "Required base image is not available locally."
      read -r -p "Would you like to build it now? [Y/n] " ans_build_base
      if [[ "${ans_build_base,,}" != "n" ]]; then
        build_missing_base "$internal_base_repo" "$required_base_image_full"
      else
        fail "Build cancelled. Please build '${required_base_image_full}' manually and retry."
      fi
    fi

    # IMPORTANT: Override the Dockerfile's default BASE_IMAGE and BASE_TAG.
    # This forces the `FROM` instruction to resolve to the exact, fully-qualified
    # local image name, preventing a remote pull.
    build_args+=("--build-arg" "BASE_TAG=develop")
    build_args+=("--build-arg" "BASE_IMAGE=${required_base_repo_full}")
  fi

  # --- Execute the Build ---
  # Normalize the final tag to include 'docker.io/' for consistency.
  local final_image_tag="docker.io/${REPO}:${DEV_TAG}"

  echo ""
  log_info "Building DEV: ${final_image_tag} (target=${DEV_TARGET})"
  set -x # Print the final command for easy debugging

  docker build \
    --progress=plain \
    "${build_args[@]}" \
    --target "$DEV_TARGET" \
    -f "$DOCKERFILE" \
    -t "$final_image_tag" \
    "$REPO_ROOT"

  set +x
}

# Helper function to build a missing base image dependency.
build_missing_base() {
  local base_repo_short="$1" # e.g., "squirrelworksllc/ubuntu-noble-core"
  local base_image_full="$2" # e.g., "docker.io/squirrelworksllc/ubuntu-noble-core:develop"

  log_info "Looking up config to build '${base_repo_short}'..."
  local base_config_json
  base_config_json="$(jq -r --arg r "$base_repo_short" '.images[] | select(.repo==$r)' "$CONFIG_FILE")"
  [[ -n "$base_config_json" ]] || fail "Could not find config for base image '$base_repo_short' in $CONFIG_FILE"

  local base_df
  local base_tgt
  base_df="$(jq -r '.dockerfile' <<<"$base_config_json")"
  base_tgt="$(jq -r '.devTarget // "develop"' <<<"$base_config_json")"

  log_info "Building missing base image: ${base_image_full}"
  set -x
  docker build \
    --progress=plain \
    --target "$base_tgt" \
    -f "$base_df" \
    -t "$base_image_full" \
    "$REPO_ROOT" || fail "Failed to build the required base image. Please fix the error and retry."
  set +x
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
