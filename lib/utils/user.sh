#!/bin/bash

# Utilities for identifying the current user's role/capabilities.
# Sourced by ih-setup via bin/ih-setup (which loads every lib/utils/*.sh).

# Holds the last role check result: "engineer", "not-engineer", or "unknown".
# The shell reminder in lib/core/shell/default/95_agent_setup.sh reads this file
# so that new terminals do not call the GitHub API.
IH_USER_ROLE_MARKER="${HOME}/.config/ih-setup/user-role"

function ih::user::write-role() {
  mkdir -p "$(dirname "$IH_USER_ROLE_MARKER")"
  echo "$1" >"$IH_USER_ROLE_MARKER"
}

# Returns 0 when the GitHub CLI can confirm the user is in the Engineering team.
# Returns 1 when the user is confirmed not to be an engineer, and also when the
# result is uncertain (CLI unavailable, not authenticated, API unreachable).
# We default to "not an engineer" to avoid running engineer-only steps, and
# warn on uncertain results so the user knows why steps were skipped.
function ih::user::is-engineer() {
  if ! command -v gh >/dev/null 2>&1; then
    ih::log::warn "Could not check whether you are an engineer: the gh CLI is not installed. Skipping engineer-only steps."
    ih::user::write-role "unknown"
    return 1
  fi
  # gh embeds a jq evaluator; --jq avoids depending on a system jq.
  local TEAM_NAMES
  if ! TEAM_NAMES=$(gh api /user/teams --jq '.[].name' 2>/dev/null); then
    ih::log::warn "Could not check whether you are an engineer: 'gh api /user/teams' failed. Run 'gh auth login' and retry. Skipping engineer-only steps."
    ih::user::write-role "unknown"
    return 1
  fi
  if grep -qx "Engineering" <<<"$TEAM_NAMES"; then
    ih::user::write-role "engineer"
    return 0
  fi
  ih::user::write-role "not-engineer"
  return 1
}
