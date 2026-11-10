#!/bin/bash

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.

# Written after a test notification succeeds. A script cannot read the
# notification permission without showing a banner, so the test checks this file.
IH_NOTIFICATIONS_OK_FILE="${HOME}/.ih/state/notifications.ok"

function ih::setup::core.notifications::help() {
  echo 'Allow ih-setup to show notifications that open their log

    This step will:
    - Ask you to allow notifications for terminal-notifier
      in System Settings, and wait for you to confirm
    - Send a test notification to make sure that the permission is on

    The background updaters use terminal-notifier for failure
    notifications. When you click one, it opens the log file.'
}

function ih::setup::core.notifications::test() {
  if ! ih::notify::find-terminal-notifier >/dev/null; then
    ih::log::debug "terminal-notifier is not installed"
    return 1
  fi
  if [ ! -f "$IH_NOTIFICATIONS_OK_FILE" ]; then
    ih::log::debug "No successful test notification is recorded in $IH_NOTIFICATIONS_OK_FILE"
    return 1
  fi
}

function ih::setup::core.notifications::deps() {
  echo ""
}

# Sends a test notification. Returns non-zero if macOS blocks it.
function ih::setup::core.notifications::send-test() {
  local notifier="$1"
  "$notifier" -title "IH Setup" \
    -message "Notifications from ih-setup are on. You can dismiss this." \
    -group "ih-setup-test" >/dev/null 2>&1
}

function ih::setup::core.notifications::record-ok() {
  mkdir -p "$(dirname "$IH_NOTIFICATIONS_OK_FILE")"
  touch "$IH_NOTIFICATIONS_OK_FILE"
  ih::log::info "Notifications for terminal-notifier are on"
}

function ih::setup::core.notifications::install() {
  local notifier
  if ! notifier="$(ih::notify::find-terminal-notifier)"; then
    ih::log::error "terminal-notifier is not installed. Run 'brew install terminal-notifier', then run this step again."
    return 1
  fi

  # If the permission is already on, or macOS asks and you allow it, nothing else is needed.
  if ih::setup::core.notifications::send-test "$notifier"; then
    ih::setup::core.notifications::record-ok
    return 0
  fi

  rm -f "$IH_NOTIFICATIONS_OK_FILE"
  echo "Notifications are turned off for terminal-notifier."
  echo "ih-setup uses it to tell you when a background update fails."
  echo ""
  echo "To turn them on:"
  echo "  1. In System Settings, open Notifications. ih-setup opens it for you."
  echo "  2. In the application list, select terminal-notifier."
  echo "  3. Turn on Allow notifications."
  echo ""
  open "x-apple.systempreferences:com.apple.Notifications-Settings.extension" 2>/dev/null || true
  ih::ask::enter-continue "When you turned on notifications, press Enter to send a test notification."

  if ih::setup::core.notifications::send-test "$notifier"; then
    ih::setup::core.notifications::record-ok
    return 0
  fi

  ih::log::error "Notifications for terminal-notifier are still turned off. Turn on Allow notifications for terminal-notifier in System Settings > Notifications, then run this step again."
  return 1
}
