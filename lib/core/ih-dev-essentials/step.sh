#!/bin/bash

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.

function ih::setup::core.ih-dev-essentials::help() {
  echo 'Install and update the ih-dev-essentials Claude Code plugin

    This step will:
    - Add the ih-coding-agents marketplace (ConsultingMD/ih-agent-smith)
    - Install and enable the ih-dev-essentials plugin for your user
    - Update every plugin you installed from ih-coding-agents
      to what the marketplace publishes

    Claude Code must be closed while this step runs.'
}

function ih::setup::core.ih-dev-essentials::test() {
  ih::claude::ensure-path

  if ! ih::claude::marketplace-registered; then
    ih::log::debug "The $IH_CLAUDE_MARKETPLACE marketplace is not registered"
    return 1
  fi

  local STATE
  STATE=$(ih::claude::plugin-state)
  if [ "$STATE" != "enabled" ]; then
    ih::log::debug "$IH_CLAUDE_PLUGIN is $STATE"
    return 1
  fi

  if ! ih::claude::plugins-up-to-date; then
    ih::log::debug "Plugins from $IH_CLAUDE_MARKETPLACE are out of date"
    return 1
  fi
}

function ih::setup::core.ih-dev-essentials::deps() {
  # core.github sets up the SSH key that the marketplace clone uses.
  echo "core.claude-code core.github"
}

function ih::setup::core.ih-dev-essentials::install() {
  ih::claude::ensure-path

  while ih::claude::is-running; do
    # Without a terminal the prompt reads nothing and would retry forever.
    if [ ! -t 0 ] || ! ih::ask::retry-cancel "Claude Code is running. Quit every Claude Code session, then retry."; then
      ih::log::error "Claude Code must be closed to install or update plugins"
      return 1
    fi
  done

  if ! ih::claude::marketplace-registered; then
    ih::log::info "Adding the $IH_CLAUDE_MARKETPLACE marketplace"
    claude plugin marketplace add "$IH_CLAUDE_MARKETPLACE_REPO" || return 1
  fi

  case "$(ih::claude::plugin-state)" in
    missing)
      ih::log::info "Installing $IH_CLAUDE_PLUGIN"
      claude plugin install "$IH_CLAUDE_PLUGIN" --scope user || return 1
      ;;
    disabled)
      ih::log::info "Enabling $IH_CLAUDE_PLUGIN"
      claude plugin enable "$IH_CLAUDE_PLUGIN" --scope user || return 1
      ;;
  esac

  ih::log::info "Updating plugins from $IH_CLAUDE_MARKETPLACE"
  ih::claude::refresh-plugins
}
