#!/bin/bash

# This script decrypts the JIRA creds file
# and evals it to load the JIRA token

eval gpg --use-agent --no-tty --quiet -o - "$HOME/.jira/creds.gpg"
