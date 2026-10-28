#!/bin/bash

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.

function ih::setup::core.twg::help() {
  echo 'Install the twg CLI (Atlassian Teamwork Graph) and log in

    This step will:
        - Install the twg CLI with its native installer, if it is missing
        - Run twg setup if you are not logged in (opens a browser to log in)
    '
}

# Check if the step has been installed and return 0 if it has.
# Otherwise return 1.
function ih::setup::core.twg::test() {
  if ! ih::path::has-command twg; then
    ih::log::debug "twg is not on the PATH or in ~/.local/bin"
    return 1
  fi

  if ! ih::setup::core.twg::signed-in; then
    ih::log::debug "twg is not logged in"
    return 1
  fi
}

# Returns 0 if twg is logged in. `twg whoami` exits 0 for a valid login and
# 77 (AUTH_REQUIRED) when there are no credentials.
function ih::setup::core.twg::signed-in() {
  twg whoami >/dev/null 2>&1
}

# core.shell puts ~/.local/bin on the PATH, where the twg installer puts the CLI.
function ih::setup::core.twg::deps() {
  echo "core.shell"
}

# Installs the twg CLI if it is missing, then runs its interactive setup
# (skills, login, upkeep) if twg is not logged in. twg upgrades itself after
# the first install. Returns 1 if twg is still not set up, so the step stays pending.
function ih::setup::core.twg::install() {
  if ! ih::path::has-command twg; then
    ih::log::info "Installing the twg CLI"
    if ! curl -fsSL --retry 2 https://teamwork-graph.atlassian.com/cli/install | bash; then
      ih::log::error "The twg installer failed"
      return 1
    fi
    if ! ih::path::has-command twg; then
      ih::log::error "The installer finished but twg is not in ~/.local/bin"
      return 1
    fi
  fi

  if ih::setup::core.twg::signed-in; then
    return 0
  fi

  # Setup opens a browser for the Atlassian login, so it only runs in a terminal.
  if [[ ! -t 0 || ! -t 1 ]]; then
    ih::log::warn "Run 'twg setup' in a terminal to finish the twg setup."
    return 1
  fi
  if ! twg setup; then
    ih::log::warn "twg setup did not finish. Run 'twg setup' again later."
    return 1
  fi
}
