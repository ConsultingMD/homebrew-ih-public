#!/bin/bash

# This script decrypts the JIRA creds file
# and evals it to load the JIRA token
if [ -z "$JIRA_API_TOKEN" ]; then
  JIRA_API_TOKEN=$(security find-generic-password -s "jira-api" -w)
  export JIRA_API_TOKEN
fi
