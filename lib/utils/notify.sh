#!/bin/bash

# Lightweight macOS notification + throttle helpers.
# Uses terminal-notifier when it is installed, else the built-in osascript.

# ih::notify::mac "Title" "Body" [file_to_open]
# Shows a Notification Center banner on macOS.
# If terminal-notifier is installed and you give a file, a click on the
# banner opens that file. An osascript banner cannot do this: macOS opens
# Script Editor when you click it.
function ih::notify::mac() {
  local title="${1:?title is required}"
  local body="${2:-}"
  local open_file="${3:-}"

  # launchd jobs can run with a PATH that does not include Homebrew.
  local notifier
  notifier="$(command -v terminal-notifier 2>/dev/null || true)"
  if [ -z "$notifier" ]; then
    for candidate in /opt/homebrew/bin/terminal-notifier /usr/local/bin/terminal-notifier; do
      if [ -x "$candidate" ]; then
        notifier="$candidate"
        break
      fi
    done
  fi

  if [ -n "$notifier" ]; then
    local args=(-title "$title" -message "$body")
    if [ -n "$open_file" ]; then
      args+=(-open "file://${open_file}")
    fi
    "$notifier" "${args[@]}" >/dev/null 2>&1 && return 0
  fi

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
  age=$((now - mtime))
  if [ "$age" -ge "$window_seconds" ]; then
    # Refresh sentinel and allow notify
    touch "$sentinel_path"
    return 0
  fi
  return 1
}
