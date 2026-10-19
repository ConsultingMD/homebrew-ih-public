#!/bin/bash

# This script decrypts the JIRA creds file
# and evals it to load the JIRA token
if [ -z "$JIRA_API_TOKEN" ]; then
  JIRA_API_TOKEN=$(security find-generic-password -s "jira-api" -w)
  export JIRA_API_TOKEN
fi

# The twg installer puts twg in ~/.local/bin.
[[ ! "$PATH" =~ ${HOME}/.local/bin ]] && export PATH="${HOME}/.local/bin:${PATH}"
