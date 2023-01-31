#!/bin/sh

# This file defines the user-specific environment variables
# which are expected by other engineering scripts,
# as well as any additional things you want to add.

# This file will be sourced before any files in the default directory.

# This file will not be updated when you update the ih-core brew formula.

# Directory where you want to clone Legacy Grand Rounds repos,
# which are currently located in the ConsultingMD org.
export IH_HOME="$HOME/src/github.com/ConsultingMD"
# This is exported for compatibility with older scripts
export GR_HOME="$IH_HOME"

# Your Included Health email address
export EMAIL_ADDRESS=

# Your GitHub username
export GITHUB_USER=

# The email address you want to associate with commits.
# If you want to keep your email address private, or have configured
# your email address to be protected in GitHub, follow the guidance
# at https://docs.github.com/en/account-and-profile/setting-up-and-managing-your-github-user-account/managing-email-preferences/setting-your-commit-email-address
# and put the no-reply email address here. Otherwise you can leave this as is.
export GITHUB_EMAIL_ADDRESS="$EMAIL_ADDRESS"

# Your full name, the name you would introduce yourself with.
export FULL_NAME=""

# Your username, probably firstname.lastname
export IH_USERNAME=
# This is exported for compatibility with older scripts
export GR_USERNAME="$IH_USERNAME"

# The username you have in JIRA.
# Before 1/15/2022:
# If you've already logged in to JIRA with an email address,
# use that. Otherwise, if you're new, use "$GR_USERNAME@grandrounds.com"
# After 7/17/2022:
# Use $GR_USERNAME@includedhealth.com
export JIRA_USERNAME=

# This is the default value used to authenticate to AWS resources
# using the aws-environment script. Most people don't need to change this.
export AWS_DEFAULT_ROLE=dev
