#!/usr/bin/env bash

# docker-context-check.sh
# Handles identifying the current Docker context and managing the background
# execution prompt if a remote context is detected.

# Determine the correct Docker context. When running inside WSL,
# 'docker context show' might return 'default', but the user's selected
# context in Windows Docker Desktop is available via 'docker.exe'.
get_docker_context() {
  if command -v docker.exe >/dev/null 2>&1; then
    docker.exe context show | tr -d '\r'
  else
    docker context show
  fi
}

# Function to check context and prompt for backgrounding
check_and_background() {
  local current_context="$1"
  local bg_running="$2"
  local build_mode="$3"
  local image_key="$4"
  local arg_apt_debug="$5"
  local arg_auto_build_base="$6"
  local script_path="$7"

  # 2. Check for Remote Context + skip if already backgrounded
  if [[ "$current_context" != "default" && "$bg_running" != "true" ]]; then
      echo "--------------------------------------------------------"
      echo "🌐 REMOTE CONTEXT DETECTED: $current_context"
      echo "--------------------------------------------------------"
      read -r -p "❓ Would you like to run this in 'No-Hangup' background mode? (y/n): " choice
      
      if [[ "$choice" =~ ^[Yy]$ ]]; then
          # Create a unique log file for this build
          LOG_DIR="logs"
          LOG_NAME="${LOG_DIR}/build_${current_context}_$(date +%Y%m%d_%H%M%S).log"
          mkdir -p "$LOG_DIR"
          
          # DYNAMIC ECHO: Tells you exactly where it is going
          echo "🚀 Detaching process to remote engine: [$current_context]"
          echo "📝 Follow logs with: tail -f $LOG_NAME"
          
          # Re-execute the script with flags to prevent loops and pass state
          nohup "$script_path" --bg-running \
            --mode "$build_mode" \
            --image "$image_key" \
            --apt-debug "$arg_apt_debug" \
            --auto-build-base "$arg_auto_build_base" \
            > "$LOG_NAME" 2>&1 < /dev/null &
          
          # Small sleep to ensure the process started before the parent shell exits
          sleep 1
          exit 0
      else
          echo "🖥️  Continuing in foreground mode on [$current_context]. Do not close this terminal."
      fi
  fi
}
