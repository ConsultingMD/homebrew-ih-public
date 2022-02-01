#!/bin/bash

# This script decrypts the JIRA creds file
# and evals it to load the JIRA token
if [ -z "$JIRA_USERNAME" ]; then
  # Back compat for people who already encrypted their JIRA creds
  if [ -f "$HOME/.jira/creds.gpg" ]; then
    eval gpg --use-agent --no-tty --quiet -o - "$HOME/.jira/creds.gpg"
  fi
fi

if [ -z "$JIRA_API_TOKEN" ]; then
  JIRA_API_TOKEN=$(security find-generic-password -s "jira-api" -w)
  export JIRA_API_TOKEN
fi
