#!/bin/bash

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.

function ih::setup::core.cursor-settings::help() {
  echo 'Add the Included Health default settings to ~/.cursor/cli-config.json

    This step will:
    - Add each default from standards/cursor-cli-config.json in ih-agent-smith
      that ih-setup never added before
    - Keep every value that is already in your settings
    - Record each default it adds in ~/.ih/state, so a default
      that you delete stays deleted

    This step runs even if Cursor is not installed.'
}

function ih::setup::core.cursor-settings::test() {
  ih::cursor::apply-cli-config-defaults test
}

function ih::setup::core.cursor-settings::deps() {
  # The defaults come from the marketplace clone that this step sets up.
  echo "core.ih-dev-essentials"
}

function ih::setup::core.cursor-settings::install() {
  ih::cursor::apply-cli-config-defaults
}
