#!/usr/bin/env bash

# docker-build.sh
# Core build logic functions for lint, prod, dev, clean, and base building.

# --- LINT BUILD ---
run_lint_build() {
  log_info "Running LINT build for '${IMAGE_KEY}' (target=${LINT_TARGET})"
  docker --context "$CURRENT_CONTEXT" build \
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
  printf " - %s
" "${images_to_clean[@]}"
  echo ""
  read -r -p "Continue? [Y/n] " ans
  [[ "${ans,,}" == "n" ]] && fail "Clean operation cancelled."

  docker --context "$CURRENT_CONTEXT" image rm -f "${images_to_clean[@]}"
}

# --- PRODUCTION BUILD ---
run_prod_build() {
  [[ -n "$PROD_TAG" ]] || fail "prodTags array is empty or not set for key '$IMAGE_KEY' in $CONFIG_FILE"
  log_info "Building PROD: ${REPO}:${PROD_TAG}"

  docker --context "$CURRENT_CONTEXT" build \
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
    local ans="${ARG_APT_DEBUG}"
    if [[ -z "$ans" ]]; then
      if [[ "$ARG_BG_RUNNING" == "true" ]]; then
        ans="n"
      else
        read -r -p "Enable APT debug output for this DEV build? [y/N]: " ans
      fi
    fi
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
    if ! docker --context "$CURRENT_CONTEXT" image inspect "$required_base_image_full" &>/dev/null; then
      local ans_build_base="${ARG_AUTO_BUILD_BASE}"
      if [[ -z "$ans_build_base" ]]; then
        if [[ "$ARG_BG_RUNNING" == "true" ]]; then
          ans_build_base="n"
        else
          echo ""
          log_info "Required base image is not available locally."
          read -r -p "Would you like to build it now? [Y/n] " ans_build_base
        fi
      fi
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

  docker --context "$CURRENT_CONTEXT" build \
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
  docker --context "$CURRENT_CONTEXT" build \
    --progress=plain \
    --target "$base_tgt" \
    -f "$base_df" \
    -t "$base_image_full" \
    "$REPO_ROOT" || fail "Failed to build the required base image. Please fix the error and retry."
  set +x
}
