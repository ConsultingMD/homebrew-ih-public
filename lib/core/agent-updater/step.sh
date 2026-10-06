#!/bin/bash

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.

IH_AGENT_UPDATER_LABEL="com.includedhealth.agent-updater"
IH_AGENT_UPDATER_PLIST="${HOME}/Library/LaunchAgents/${IH_AGENT_UPDATER_LABEL}.plist"

function ih::setup::core.agent-updater::help() {
  echo 'Keep the standard agent setup up to date in the background

    This step will:
    - Install a launchd agent that runs weekly and at login while
      Claude Code is closed. It updates the ih-coding-agents plugins,
      the managed AGENTS.md, and new Claude settings defaults.
    - Write a log to ~/.ih/logs/agent-updater.log
    - Show a macOS notification when an update fails

    If an update failed, this step shows as not installed.
    Installing it again runs the update now.'
}

# Echoes the path of a temp copy of the plist with its variables filled in.
function ih::setup::core.agent-updater::create-temp-plist() {
  local TEMP_PLIST
  TEMP_PLIST=$(mktemp /tmp/ih_agent_updater.XXXXXX)

  local LIB_ESC HOME_ESC
  # shellcheck disable=SC2001
  LIB_ESC=$(echo "$IH_CORE_LIB_DIR" | sed 's_/_\\/_g')
  # shellcheck disable=SC2001
  HOME_ESC=$(echo "$HOME" | sed 's_/_\\/_g')

  sed "s/\$IH_CORE_LIB_DIR/${LIB_ESC}/g; s/\$HOME/${HOME_ESC}/g" \
    "$IH_CORE_LIB_DIR/core/agent-updater/autoupdate/${IH_AGENT_UPDATER_LABEL}.plist" >"$TEMP_PLIST"

  echo "$TEMP_PLIST"
}

function ih::setup::core.agent-updater::test() {
  local TEMP_PLIST IN_SYNC=0
  TEMP_PLIST=$(ih::setup::core.agent-updater::create-temp-plist)
  ih::file::check-file-in-sync "$TEMP_PLIST" "$IH_AGENT_UPDATER_PLIST" || IN_SYNC=1
  rm -f "$TEMP_PLIST"
  if [ $IN_SYNC -ne 0 ]; then
    ih::log::debug "$IH_AGENT_UPDATER_PLIST is missing or out of date"
    return 1
  fi

  if ! launchctl list "$IH_AGENT_UPDATER_LABEL" >/dev/null 2>&1; then
    ih::log::debug "$IH_AGENT_UPDATER_LABEL is not loaded"
    return 1
  fi

  local STATUS_FILE="${IH_AGENT_STATE_DIR}/agent-updater.status"
  if grep -q '^failed' "$STATUS_FILE" 2>/dev/null; then
    ih::log::warn "The last agent setup update failed. See ~/.ih/logs/agent-updater.log"
    return 1
  fi
}

function ih::setup::core.agent-updater::deps() {
  echo "core.ih-dev-essentials core.agents-md core.claude-settings"
}

function ih::setup::core.agent-updater::install() {
  local TEMP_PLIST
  TEMP_PLIST=$(ih::setup::core.agent-updater::create-temp-plist)
  mkdir -p "$(dirname "$IH_AGENT_UPDATER_PLIST")"
  cp -f "$TEMP_PLIST" "$IH_AGENT_UPDATER_PLIST"
  rm -f "$TEMP_PLIST"

  if launchctl list "$IH_AGENT_UPDATER_LABEL" >/dev/null 2>&1; then
    launchctl unload "$IH_AGENT_UPDATER_PLIST"
  fi
  launchctl load "$IH_AGENT_UPDATER_PLIST" || return 1
  ih::log::info "Loaded $IH_AGENT_UPDATER_PLIST"

  # Run once now so that a failed update is retried and its status is cleared.
  if grep -q '^failed' "${IH_AGENT_STATE_DIR}/agent-updater.status" 2>/dev/null; then
    ih::log::info "Retrying the failed agent setup update"
    if ! IH_AGENT_UPDATER_FORCE=1 "$IH_CORE_LIB_DIR/core/agent-updater/autoupdate/ih_agent_updater"; then
      ih::log::error "The update failed again. See ~/.ih/logs/agent-updater.log"
      return 1
    fi
  fi
}
