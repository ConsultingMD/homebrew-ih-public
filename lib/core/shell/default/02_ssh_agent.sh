#!/bin/bash

# Changes to this file will be overwritten if you update the ih-core formula

# The macOS ssh-agent starts empty at login. Homebrew clones private formulas
# in a sandbox that can use the agent but not the Keychain, so load keys whose
# passphrases are in the Keychain. Only the local launchd agent is touched, so a
# forwarded or third-party agent can't hang shell start. Safe under set -e.
case "${SSH_AUTH_SOCK:-}" in
  /private/tmp/com.apple.launchd.*/Listeners)
    if [[ -x /usr/bin/ssh-add ]]; then
      ih_ssh_agent_rc=0
      /usr/bin/ssh-add -l >/dev/null 2>&1 || ih_ssh_agent_rc=$?
      # 1 means the agent is up but holds no keys.
      if [[ $ih_ssh_agent_rc -eq 1 ]]; then
        /usr/bin/ssh-add --apple-load-keychain -q >/dev/null 2>&1 || :
      fi
      unset ih_ssh_agent_rc
    fi
    ;;
esac
