#!/bin/bash

# Utilities for identifying the current user's role/capabilities.
# Sourced by ih-setup via bin/ih-setup (which loads every lib/utils/*.sh).

# Returns 0 when the GitHub CLI can confirm the user is in the Engineering team.
# Returns 1 when the CLI is unavailable, not authenticated, API is unreachable,
# or the Engineering team is not present — in all uncertain cases we default
# to "not an engineer" to avoid running engineer-only steps.
function ih::user::is-engineer() {
  if ! command -v gh >/dev/null 2>&1; then
    return 1
  fi
  # gh embeds a jq evaluator; --jq avoids depending on a system jq.
  local TEAM_NAMES
  TEAM_NAMES=$(gh api /user/teams --jq '.[].name' 2>/dev/null) || return 1
  grep -qx "Engineering" <<<"$TEAM_NAMES"
}

