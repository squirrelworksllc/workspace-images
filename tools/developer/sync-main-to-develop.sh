#!/usr/bin/env bash
# sync-main-to-develop.sh
# Sync main -> develop after a PR merge (POSIX-ish Bash).

set -euo pipefail

REMOTE="origin"
MAIN_BRANCH="main"
DEV_BRANCH="develop"

log() {
  printf '[sync] %s\n' "$*" >&2
}

fail() {
  printf '[sync] ERROR: %s\n' "$*" >&2
  exit 1
}

usage() {
  cat <<EOF
Usage: $0 [-r remote] [-m main_branch] [-d develop_branch]

Defaults:
  remote        = origin
  main_branch   = main
  develop_branch= develop
EOF
}

# Parse optional flags
while getopts ":r:m:d:h" opt; do
  case "$opt" in
    r) REMOTE="$OPTARG" ;;
    m) MAIN_BRANCH="$OPTARG" ;;
    d) DEV_BRANCH="$OPTARG" ;;
    h) usage; exit 0 ;;
    \?) fail "Invalid option: -$OPTARG" ;;
    :)  fail "Option -$OPTARG requires an argument." ;;
  esac
done
shift $((OPTIND - 1))

# Ensure git is available
if ! command -v git >/dev/null 2>&1; then
  fail "git is not installed or not in PATH."
fi

# Ensure we're in a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  fail "Not inside a git repository."
fi

# Stop if working tree is dirty
PORCELAIN="$(git status --porcelain)"
if [ -n "${PORCELAIN//$'\n'/}" ]; then
  printf '%s\n' "$PORCELAIN"
  fail "Working tree has uncommitted changes. Commit/stash first."
fi

# Stop if unresolved conflicts exist
CONFLICTS="$(git ls-files -u || true)"
if [ -n "${CONFLICTS//$'\n'/}" ]; then
  fail "Unresolved merge conflicts detected. Resolve them first."
fi

log "Fetching latest from $REMOTE..."
if ! git fetch "$REMOTE" --prune; then
  fail "git fetch failed."
fi

ensure_branch() {
  local branch="$1"

  if ! git show-ref --verify --quiet "refs/heads/$branch"; then
    log "Local branch '$branch' not found. Attempting to create from $REMOTE/$branch..."
    if ! git show-ref --verify --quiet "refs/remotes/$REMOTE/$branch"; then
      fail "Remote branch '$REMOTE/$branch' not found."
    fi
    if ! git checkout -b "$branch" "$REMOTE/$branch" >/dev/null 2>&1; then
      fail "Failed to create local branch '$branch'."
    fi
  fi
}

ensure_branch "$MAIN_BRANCH"
ensure_branch "$DEV_BRANCH"

log "Checking out $MAIN_BRANCH..."
if ! git checkout "$MAIN_BRANCH" >/dev/null 2>&1; then
  fail "Failed to checkout '$MAIN_BRANCH'."
fi

log "Updating $MAIN_BRANCH from $REMOTE/$MAIN_BRANCH (fast-forward only)..."
if ! git pull --ff-only "$REMOTE" "$MAIN_BRANCH"; then
  fail "Could not fast-forward '$MAIN_BRANCH'. If you have local commits/divergence, fix that first."
fi

log "Checking out $DEV_BRANCH..."
if ! git checkout "$DEV_BRANCH" >/dev/null 2>&1; then
  fail "Failed to checkout '$DEV_BRANCH'."
fi

log "Updating $DEV_BRANCH from $REMOTE/$DEV_BRANCH (fast-forward only)..."
if ! git pull --ff-only "$REMOTE" "$DEV_BRANCH"; then
  fail "Could not fast-forward '$DEV_BRANCH'. If you have local commits/divergence, fix that first."
fi

log "Merging $MAIN_BRANCH into $DEV_BRANCH..."
if ! git merge --no-edit "$MAIN_BRANCH"; then
  fail "Merge failed. Resolve conflicts, then run: git commit ; git push $REMOTE $DEV_BRANCH"
fi

log "Pushing $DEV_BRANCH to $REMOTE..."
if ! git push "$REMOTE" "$DEV_BRANCH"; then
  fail "Push failed."
fi

log "Done. '$DEV_BRANCH' now includes latest '$MAIN_BRANCH'."
