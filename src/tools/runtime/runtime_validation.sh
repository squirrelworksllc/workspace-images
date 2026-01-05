#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

###############################################################################
# runtime_validation.sh
#
# Runs runtime validation checks for this image/session.
#
# Design goals:
# - Safe by default: skip missing components and avoid breaking non-related images
# - Centralized: define all validation scripts here so workspace.json stays simple
#
# Modes:
#   VALIDATE_MODE=soft (default)
#     - Missing validator scripts or missing dependencies -> skip (exit 0)
#     - If a validator runs and fails -> log warning, continue
#
#   VALIDATE_MODE=hard
#     - Missing validator scripts -> skip (does NOT fail)
#     - If a validator runs and fails -> fail the session startup (exit nonzero)
#
# Env overrides:
#   VALIDATE_MODE (default: soft)  # soft|hard
###############################################################################

log()  { echo "[validate] $*"; }
warn() { echo "[validate] WARN: $*" >&2; }
err()  { echo "[validate] ERROR: $*" >&2; }

MODE="${VALIDATE_MODE:-soft}"

run_validator() {
  local name="$1"
  local path="$2"

  # If the validator isn't present/executable, just skip.
  if [ ! -x "$path" ]; then
    log "skip: ${name} (missing or not executable): ${path}"
    return 0
  fi

  log "run: ${name} -> ${path}"

  # We pass the mode down so validators can implement soft/hard behavior too.
  # For torsocks validator, we used VALIDATE_TORSOCKS_MODE; we map MODE -> it.
  if [ "$name" = "torsocks" ]; then
    VALIDATE_TORSOCKS_MODE="$MODE" "$path" && {
      log "pass: ${name}"
      return 0
    } || {
      local rc=$?
      if [ "$MODE" = "hard" ]; then
        err "fail: ${name} (rc=${rc})"
        return "$rc"
      fi
      warn "fail: ${name} (rc=${rc}) - continuing (mode=soft)"
      return 0
    }
  fi

  # Generic runner (for future validators that use VALIDATE_MODE di_
