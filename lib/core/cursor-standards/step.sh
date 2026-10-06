#!/bin/bash

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.

function ih::setup::core.cursor-standards::help() {
  echo "Install the Included Health standards for Cursor

    This step will:
    - Write a local Cursor plugin to ${IH_CURSOR_PLUGIN_DIR}
    - Put standards/AGENTS.md from ih-agent-smith in it as a rule
      that applies to every chat
    - Copy the skills in standards/cursor-skills.txt into it

    ih-setup owns this directory and replaces it on each update.
    This step runs even if Cursor is not installed. It does not install
    ih-dev-essentials in Cursor. To get it, type /add-plugin ih-dev-essentials
    in Cursor Agent chat."
}

function ih::setup::core.cursor-standards::test() {
  if ! ih::cursor::plugin-in-sync; then
    ih::log::debug "$IH_CURSOR_PLUGIN_DIR is missing or out of date"
    return 1
  fi
}

function ih::setup::core.cursor-standards::deps() {
  # The standards come from the marketplace clone that this step sets up.
  echo "core.ih-dev-essentials"
}

function ih::setup::core.cursor-standards::install() {
  ih::cursor::sync-plugin || return 1
  ih::log::info "Wrote $IH_CURSOR_PLUGIN_DIR. In Cursor, run Developer: Reload Window to load it."
}
