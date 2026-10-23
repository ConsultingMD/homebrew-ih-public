#!/bin/bash

# Lightweight macOS notification + throttle helpers.
# No external dependencies beyond the built-in osascript.

set -Euo pipefail

# ih::notify::mac "Title" "Body"
# Shows a Notification Center banner on macOS using osascript.
function ih::notify::mac() {
  local title="${1:?title is required}"
  local body="${2:-}"
  # Guard if osascript is unavailable (e.g., in non-macOS test shells)
  if command -v osascript >/dev/null 2>&1; then
    osascript -e "display notification \"${body}\" with title \"${title}\"" \
      >/dev/null 2>&1 || true
  fi
}

# ih::notify::throttle_by_file <sentinel_path> <seconds>
# Returns 0 when a notification should be shown (and updates the sentinel),
# or 1 when within the throttle window and the notification should be suppressed.
function ih::notify::throttle_by_file() {
  local sentinel_path="${1:?sentinel_path is required}"
  local window_seconds="${2:?window_seconds is required}"

  # If the sentinel doesn't exist or is older than the window, allow notify
  if [ ! -f "$sentinel_path" ]; then
    mkdir -p "$(dirname "$sentinel_path")" || true
    : >"$sentinel_path"
    return 0
  fi

  # macOS 'stat -f %m' returns epoch mtime; Linux 'stat -c %Y'
  local mtime now age
  if stat -f '%m' "$sentinel_path" >/dev/null 2>&1; then
    mtime="$(stat -f '%m' "$sentinel_path")"
  else
    mtime="$(stat -c '%Y' "$sentinel_path")"
  fi
  now="$(date +%s)"
  age=$(( now - mtime ))
  if [ "$age" -ge "$window_seconds" ]; then
    # Refresh sentinel and allow notify
    touch "$sentinel_path"
    return 0
  fi
  return 1
}

