#!/bin/bash

# Reminds you to install the standard agent setup until its updater is installed.

# ██████╗  ██████╗     ███╗   ██╗ ██████╗ ████████╗    ███████╗██████╗ ██╗████████╗
# ██╔══██╗██╔═══██╗    ████╗  ██║██╔═══██╗╚══██╔══╝    ██╔════╝██╔══██╗██║╚══██╔══╝
# ██║  ██║██║   ██║    ██╔██╗ ██║██║   ██║   ██║       █████╗  ██║  ██║██║   ██║
# ██║  ██║██║   ██║    ██║╚██╗██║██║   ██║   ██║       ██╔══╝  ██║  ██║██║   ██║
# ██████╔╝╚██████╔╝    ██║ ╚████║╚██████╔╝   ██║       ███████╗██████╔╝██║   ██║
# ╚═════╝  ╚═════╝     ╚═╝  ╚═══╝ ╚═════╝    ╚═╝       ╚══════╝╚═════╝ ╚═╝   ╚═╝
# Changes to this file will be overwritten if you update the ih-core formula

# The updater step is the last agent setup step, so its plist means the setup is done.
# Show this reminder only for engineers; for other roles, skip it quietly.
# The role is cached in a marker file, so a new terminal calls the GitHub API at most once.
if [[ $- == *i* ]] && [[ ! -f "${HOME}/Library/LaunchAgents/com.includedhealth.agent-updater.plist" ]]; then
  IH_USER_ROLE_MARKER="${HOME}/.config/ih-setup/user-role"
  if [[ ! -f "$IH_USER_ROLE_MARKER" ]]; then
    IH_USER_ROLE="unknown"
    if command -v gh >/dev/null 2>&1; then
      # gh embeds jq; --jq avoids a jq dependency.
      if IH_TEAM_NAMES=$(gh api /user/teams --jq '.[].name' 2>/dev/null); then
        if grep -qx "Engineering" <<<"$IH_TEAM_NAMES"; then
          IH_USER_ROLE="engineer"
        else
          IH_USER_ROLE="not-engineer"
        fi
      fi
    fi
    mkdir -p "$(dirname "$IH_USER_ROLE_MARKER")" && echo "$IH_USER_ROLE" >"$IH_USER_ROLE_MARKER"
    unset IH_USER_ROLE IH_TEAM_NAMES
  fi
  if [[ "$(cat "$IH_USER_ROLE_MARKER" 2>/dev/null)" == "engineer" ]]; then
    echo "ih-setup: The standard agent setup is not installed. Run 'brew upgrade ih-core && ih-setup install'." >&2
  fi
  unset IH_USER_ROLE_MARKER
fi
