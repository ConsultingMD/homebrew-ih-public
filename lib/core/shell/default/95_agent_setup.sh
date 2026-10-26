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
if [[ $- == *i* ]] && [[ ! -f "${HOME}/Library/LaunchAgents/com.includedhealth.agent-updater.plist" ]]; then
  IS_ENGINEER=1
  if command -v gh >/dev/null 2>&1; then
    # gh embeds jq; --jq avoids a jq dependency.
    if gh api /user/teams --jq '.[].name' 2>/dev/null | grep -qx "Engineering"; then
      IS_ENGINEER=0
    fi
  fi
  if [[ $IS_ENGINEER -eq 0 ]]; then
    echo "ih-setup: The standard agent setup is not installed. Run 'brew upgrade ih-core && ih-setup install'." >&2
  fi
fi
