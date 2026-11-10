#!/bin/bash

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.

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
  local notifier
  if ! notifier="$(ih::notify::find-terminal-notifier)"; then
    ih::log::debug "terminal-notifier is not installed"
    return 1
  fi
  # -diagnose reads the permission without showing a banner. It exits non-zero
  # when notifications are not allowed, which also catches a permission that a
  # macOS upgrade reset.
  if ! "$notifier" -diagnose >/dev/null 2>&1; then
    ih::log::debug "Notifications are not allowed for terminal-notifier"
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

# This step only warns. Blocked notifications fall back to osascript, so they
# must not fail ih-setup install, for example on a Mac where MDM blocks them.
function ih::setup::core.notifications::install() {
  local notifier
  if ! notifier="$(ih::notify::find-terminal-notifier)"; then
    ih::log::warn "terminal-notifier is not installed. Run 'brew install terminal-notifier', then run this step again."
    return 0
  fi

  # If the permission is already on, or macOS asks and you allow it, nothing else is needed.
  if ih::setup::core.notifications::send-test "$notifier"; then
    ih::log::info "Notifications for terminal-notifier are on"
    return 0
  fi

  # The steps below wait for you to press Enter, so they only run in a terminal.
  if [[ ! -t 0 || ! -t 1 ]]; then
    ih::log::warn "Notifications are turned off for terminal-notifier. Run 'ih-setup install core notifications' in a terminal to turn them on."
    return 0
  fi

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
    ih::log::info "Notifications for terminal-notifier are on"
    return 0
  fi

  ih::log::warn "Notifications for terminal-notifier are still turned off. Failure notifications will open Script Editor, not the log. Turn on Allow notifications for terminal-notifier in System Settings > Notifications, then run this step again."
  return 0
}
