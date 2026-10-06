#!/bin/bash

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.

function ih::setup::core.claude-settings::help() {
  echo 'Add the Included Health default settings to ~/.claude/settings.json

    This step will:
    - Add each default from standards/claude-settings.json in ih-agent-smith
      that ih-setup never added before
    - Keep every value that is already in your settings
    - Record each default it adds in ~/.ih/state, so a default
      that you delete stays deleted'
}

function ih::setup::core.claude-settings::test() {
  ih::claude::apply-settings-defaults test
}

function ih::setup::core.claude-settings::deps() {
  # The defaults come from the marketplace clone that this step sets up.
  echo "core.ih-dev-essentials"
}

function ih::setup::core.claude-settings::install() {
  ih::claude::apply-settings-defaults
}
