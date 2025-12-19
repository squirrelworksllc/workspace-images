#!/usr/bin/env bash
# Interactive builder for repo images (always repo-root context)
set -euo pipefail

export DOCKER_BUILDKIT=1

CONFIG=".vscode/images.json"

command -v jq >/dev/null 2>&1 || { echo "jq is required. Install jq and retry."; exit 1; }
command -v git >/dev/null 2>&1 || { echo "git is required. Install git and retry."; exit 1; }

# Ensure we're at repo root (works even if launched from elsewhere)
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[[ -n "${REPO_ROOT}" ]] || { echo "ERROR: must be run inside a git repo"; exit 10; }
cd "${REPO_ROOT}"

[[ -f "${CONFIG}" ]] || { echo "ERROR: config not found: ${CONFIG} (cwd=$(pwd))"; exit 11; }

# Extract BASE_TAG from a Dockerfile (informational only)
get_base_tag() {
  local df="$1"
  local tag=""

  tag="$(
    awk '
      /^[[:space:]]*ARG[[:space:]]+BASE_TAG=/ {
        sub(/^[[:space:]]*ARG[[:space:]]+BASE_TAG=/, "", $0)
        gsub(/"/, "", $0)
        gsub(/\047/, "", $0) # strip single quotes
        print $0
        exit
      }
    ' "$df"
  )"

  if [[ -z "${tag}" ]]; then
    echo "ERROR: Could not determine BASE_TAG from ${df} (expected: ARG BASE_TAG=...)" >&2
    exit 20
  fi

  printf '%s' "${tag}"
}

# Mode picker (default: lint)
echo ""
read -r -p "Select mode [lint/prod/dev] (default: lint): " MODE_IN
MODE="${MODE_IN:-lint}"

case "$MODE" in
  lint|prod|production|dev|develop) ;;
  *)
    echo "Unknown mode: $MODE (use lint|prod|dev)"
    exit 4
    ;;
esac

# Build list of keys
mapfile -t KEYS < <(jq -r '.images[].key' "$CONFIG")

if [[ "${#KEYS[@]}" -eq 0 ]]; then
  echo "No images found in $CONFIG"
  exit 2
fi

# Prompt user to pick an image key
echo ""
echo "Select image:"
select KEY in "${KEYS[@]}"; do
  if [[ -n "${KEY:-}" ]]; then
    break
  fi
  echo "Invalid selection."
done

img="$(jq -r --arg key "$KEY" '.images[] | select(.key==$key)' "$CONFIG")"
if [[ -z "$img" || "$img" == "null" ]]; then
  echo "Image key '$KEY' not found in $CONFIG"
  exit 3
fi

dockerfile="$(jq -r '.dockerfile' <<<"$img")"
repo="$(jq -r '.repo' <<<"$img")"

[[ -f "$dockerfile" ]] || { echo "ERROR: Dockerfile not found: $dockerfile"; exit 12; }

echo ""
echo "Key:        $KEY"
echo "Dockerfile: $dockerfile"
echo "Context:    . (repo root enforced)"

# Enforce repo-root context no matter what images.json says
ROOT_CONTEXT="."

# Helper to read a field from the selected image JSON
img_field() {
  local field="$1"
  jq -r --arg f "$field" '.[$f] // empty' <<<"$img"
}

prod_tag_from_json() {
  local t
  t="$(img_field "prodTag")"
  if [[ -z "$t" || "$t" == "null" ]]; then
    echo "ERROR: prodTag is not set for key '$KEY' in $CONFIG" >&2
    echo "       Add: \"prodTag\": \"1.18.0\" (this is YOUR published tag, not BASE_TAG)" >&2
    exit 21
  fi
  printf '%s' "$t"
}

dev_tag_from_json() {
  local t
  t="$(img_field "devTag")"
  [[ -n "$t" && "$t" != "null" ]] || t="develop"
  printf '%s' "$t"
}

case "$MODE" in
  dev|develop)
    tag="$(dev_tag_from_json)"
    target="$(img_field "devTarget")"
    [[ -n "$target" && "$target" != "null" ]] || { echo "ERROR: devTarget missing for $KEY"; exit 22; }

    echo ""
    echo "Building DEV: ${repo}:${tag} (target=${target})"
    docker build --progress=plain --target "$target" -f "$dockerfile" -t "${repo}:${tag}" "$ROOT_CONTEXT"
    ;;
  lint)
    target="$(img_field "lintTarget")"
    [[ -n "$target" && "$target" != "null" ]] || target="lint"

    echo ""
    echo "Running LINT build: (target=${target})"
    docker build --progress=plain --no-cache --target "$target" -f "$dockerfile" "$ROOT_CONTEXT"
    ;;
  prod|production)
    tag="$(prod_tag_from_json)"
    base_tag="$(get_base_tag "$dockerfile")"

    echo ""
    echo "Building PROD: ${repo}:${tag}"
    echo "  (Dockerfile BASE_TAG for kasm base image is: ${base_tag})"

    docker build --progress=plain -f "$dockerfile" -t "${repo}:${tag}" "$ROOT_CONTEXT"
    ;;
esac
