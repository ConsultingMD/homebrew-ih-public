#!/bin/bash

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.

function ih::setup::core.twg::help() {
  echo 'Install the twg CLI (Atlassian Teamwork Graph) and log in

    This step will:
        - Install the twg CLI with its native installer, if it is missing
        - Run twg setup if you are not logged in (opens a browser to log in)
        - If twg setup fails, log in again with the site cloud ID
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
  if twg setup; then
    return 0
  fi

  ih::log::warn "twg setup did not finish. Trying to log in with the site cloud ID."
  if ih::setup::core.twg::login-with-cloud-id; then
    # The login worked, but twg setup stopped there. Run it again so that it
    # skips the login and finishes the skills and the upkeep.
    if ! twg setup; then
      ih::log::warn "twg is logged in, but twg setup did not finish. Run 'twg setup' again later."
    fi
    return 0
  fi
  ih::log::warn "twg setup did not finish. Run 'twg setup' again later."
  return 1
}

# The Atlassian site that IH uses. Its public tenant info holds the cloud ID.
IH_TWG_SITE_HOST="includedhealth.atlassian.net"

# Prints the cloud ID of the IH Atlassian site, or nothing if the lookup fails.
function ih::setup::core.twg::cloud-id() {
  curl -fsSL --max-time 10 "https://${IH_TWG_SITE_HOST}/_edge/tenant_info" 2>/dev/null \
    | sed -n 's/.*"cloudId" *: *"\([^"]*\)".*/\1/p'
}

# Fallback for a login that fails on the site name. On Island, DNS returns
# 100.64.0.0/10 addresses for the Atlassian hosts, and twg rejects them as
# non-public. A login with the cloud ID skips the name lookup. If a stale
# profile is the cause, the stale profile must be cleared first.
# This only runs after `twg setup` failed, so the user has no working login to lose.
# Returns 0 if twg is logged in at the end.
function ih::setup::core.twg::login-with-cloud-id() {
  local cloud_id profile
  cloud_id=$(ih::setup::core.twg::cloud-id)
  if [[ -z "${cloud_id}" ]]; then
    ih::log::debug "could not read the cloud ID from ${IH_TWG_SITE_HOST}"
    return 1
  fi

  local profiles_file="${HOME}/.config/twg/auth-profiles.json"
  # Keep the first backup. A second run must not replace it with a logged-out file.
  if [[ -f "${profiles_file}" && ! -e "${profiles_file}.bak" ]]; then
    cp -p "${profiles_file}" "${profiles_file}.bak"
    ih::log::info "Saved a copy of the twg profiles to ${profiles_file}.bak"
  fi

  # Newer twg versions list the login profile in `twg doctor`.
  profile=$(twg doctor 2>/dev/null | sed -n 's/^ *Login profile: *//p' | head -n 1)
  if [[ -n "${profile}" ]]; then
    twg logout --profile "${profile}" >/dev/null 2>&1
  else
    twg logout >/dev/null 2>&1
  fi

  twg login --site "${cloud_id}" || return 1
  ih::setup::core.twg::signed-in
}
