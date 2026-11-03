#!/bin/bash

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.

# Cloud ID of includedhealth.atlassian.net.
IH_TWG_CLOUD_ID="e2f54acf-2b9b-45b2-9345-f65f2c861d48"

function ih::setup::core.twg::help() {
  echo 'Install the twg CLI (Atlassian Teamwork Graph) and log in

    This step will:
        - Install the twg CLI with its native installer, if it is missing
        - If you are not logged in: remove any stale twg login profile,
          log in to Included Health by cloud ID (opens a browser), install
          the twg agent skills, and enable twg upkeep
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

# Installs the twg CLI if it is missing, then logs in and installs skills and
# upkeep if twg is not logged in. twg upgrades itself after the first install.
# Returns 1 if twg is still not logged in, so the step stays pending.
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
    ih::log::warn "Run 'ih-setup install core twg' in a terminal to log in to twg."
    return 1
  fi
  # On Island, DNS maps *.atlassian.net to 100.64.0.0/10 tunnel addresses, which
  # twg rejects as non-public. A fresh login by hostname fails, and so does any
  # login while a stale profile exists, so drop that profile and log in by cloud ID.
  local profiles="$HOME/.config/twg/auth-profiles.json"
  if [[ -f "$profiles" ]]; then
    cp -p "$profiles" "$profiles.bak"
    ih::log::info "Removing the stale twg login profile (backup: $profiles.bak)"
    twg logout || ih::log::debug "twg logout failed; continuing with login"
  fi
  if ! twg login --site "$IH_TWG_CLOUD_ID"; then
    ih::log::warn "twg login did not finish. Run 'twg login --site $IH_TWG_CLOUD_ID' again later."
    return 1
  fi
  # The rest of `twg setup`. twg 1.4.2's setup fails once any profile exists
  # ("--user only applies with --pat"), so run its parts directly.
  twg skills install -y || ih::log::warn "twg skills install failed. Run 'twg skills install' later."
  twg upkeep enable || ih::log::warn "twg upkeep enable failed. Run 'twg upkeep enable' later."
}
