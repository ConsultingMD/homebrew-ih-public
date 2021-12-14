#!/bin/bash

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.

function ih::setup::core.jira::help() {
  echo 'Configure JIRA API token for story automation

    This step will:
        - Help you create a token
        - Encrypt the token for use by JIRA CLI tools
    '
}

# Check if the step has been installed and return 0 if it has.
# Otherwise return 1.
function ih::setup::core.jira::test() {
  local JIRA_FILE="$HOME/.ih/default/09_jira.sh"

  if [[ ! -f "$JIRA_FILE" ]]; then
    ih::log::debug "JIRA augment file not found at $JIRA_FILE"
    return 1
  fi
}

function ih::setup::core.jira::deps() {
  echo "core.shell"
}

function ih::setup::core.jira::install() {
  local JIRA_FILE="$HOME/.ih/default/10_jira.sh"
  local KEYCHAIN_NAME=${TEST_KEYCHAIN:-default}

  ih::ask::confirm "You will need to log in to JIRA and create an API token.
Your JIRA login is $JIRA_USERNAME.

When you press Y I will open a browser to https://id.atlassian.com/manage/api-tokens.

Please log in to JIRA (if you haven't already), create an API token
with a label like 'jira-cli', and copy the token to your clipboard.
If you don't want to do this now, press n.
" || return 1

  open "https://id.atlassian.com/manage/api-tokens"

  local TOKEN
  read -r -s -p "Paste token here:" TOKEN
  echo ""

  ih::ask::yes-no-retry "Your token appears to start with ${TOKEN:0:4}
Is that correct?"
  local YNR=$?
  echo "YNR=$YNR"
  if [[ $YNR -eq 2 ]]; then
    return 2
  elif [[ $YNR -eq 1 ]]; then
    # Let them try again or give up
    ih::setup::core.jira::install
    return $?
  fi

  security add-generic-password -a "$JIRA_USERNAME" -s "jira-api" -w "$TOKEN" -j "API Token for JIRA" "$KEYCHAIN_NAME"

  cp -f "$IH_CORE_LIB_DIR/core/jira/default/09_jira.sh" "$IH_DEFAULT_DIR/09_jira.sh"
}
