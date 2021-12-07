#!/bin/bash

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.

function ih::setup::jira::help() {
  echo 'Configure JIRA API token for story automation

    This step will:
        - Help you create a token
        - Encrypt the token for use by JIRA CLI tools
    '
}

# Check if the step has been installed and return 0 if it has.
# Otherwise return 1.
function ih::setup::jira::test() {
  local CREDS_DIR="$HOME/.jira"
  local CREDS_FILE="$CREDS_DIR/creds.gpg"
  local JIRA_FILE="$HOME/.ih/default/10_jira.sh"

  if [[ ! -f "$CREDS_FILE" ]]; then
    ih::log::debug "JIRA creds not found at $CREDS_FILE"
    return 1
  fi

  if [[ ! -f "$JIRA_FILE" ]]; then
    ih::log::debug "JIRA augment file not found at $JIRA_FILE"
    return 1
  fi
}

# Echo a space-delimited list of steps which must be installed before this one can be.
function ih::setup::jira::deps() {
  echo "shell"
}

function ih::setup::jira::disabled-install() {
  local JIRA_FILE="$HOME/.ih/default/10_jira.sh"
  local CREDS_DIR="$HOME/.jira"
  local CREDS_FILE="$CREDS_DIR/creds.gpg"

  ih::private::confirm "You will need to log in to JIRA and
create an API token. Your JIRA login is $JIRA_USERNAME. Please
open the address below in a browser, create an API token
with a label like 'jira-cli', and copy the token to your clipboard.
When you've done that, enter Y. If you don't want to do this now, press n.

https://id.atlassian.com/manage/api-tokens

" || return 1

  local TOKEN
  read -r -s -p "Paste token here:" TOKEN
  echo ""

  ih::private::yes-no-retry "Your token appears to start with ${TOKEN:0:4}
Is that correct?"
  local YNR=$?
  echo "YNR=$YNR"
  if [[ $YNR -eq 2 ]]; then
    return 2
  elif [[ $YNR -eq 1 ]]; then
    # Let them try again or give up
    ih::setup::jira::install
    return $?
  fi

  mkdir -p "$CREDS_DIR"

  gpg -e -r "$EMAIL_ADDRESS" -o "$CREDS_FILE" - <<GPG
export JIRA_API_TOKEN=$TOKEN
GPG

  cp -f "$IH_CORE_BIN_DIR/steps/jira/default/09_jira.sh" "$IH_DEFAULT_DIR/09_jira.sh"
}
