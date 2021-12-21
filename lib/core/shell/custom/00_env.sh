#!/bin/sh

# This file defines the user-specific environment variables
# which are expected by other engineering scripts,
# as well as any additional things you want to add.

# This file will be sourced before any files in the default directory.

# This file will not be updated when you update the ih-core brew formula.

# Directory where you want to clone Legacy Grand Rounds repos,
# which are currently located in the ConsultingMD org.
export GR_HOME="$HOME/src/github.com/ConsultingMD"

# Directory where you want to clone Legacy Doctor on Demand repos,
# which are currently located in the doctorondemand org.
export DOD_HOME="$HOME/src/github.com/doctorondemand"

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

# Your 3 character initials
export INITIALS=

# Your full name, the name you would introduce yourself with.
export FULL_NAME=""

# Your username, probably firstname.lastname
export IH_USERNAME=
# This is copied for legacy compatibility
export GR_USERNAME="$IH_USERNAME"

# The username you have in JIRA.
# Before 1/15/2022:
# If you've already logged in to JIRA with an email address,
# use that. Otherwise, if you're new, use "$GR_USERNAME@grandrounds.com"
# After 1/15/2022:
# Use $GR_USERNAME@includedhealth.com
export JIRA_USERNAME=

# This is the default value used to authenticate to AWS resources
# using the aws-environment script. Most people don't need to change this.
export AWS_DEFAULT_ROLE=developer
