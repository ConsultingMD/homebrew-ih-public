#!/bin/sh

# This file defines the user-specific environment variables
# which are expected by other engineering scripts,
# as well as any additional things you want to add.

# This file will not be updated when you update the ih-core brew formula.

# Directory where you want to clone Legacy Grand Rounds repos,
# which are currently located in the ConsultingMD org.
export GR_HOME="$HOME/src/github.com/ConsultingMD"

# Directory where you want to clone Legacy Doctor on Demand repos,
# which are currently located in the doctorondemand org.
export DOD_HOME="$HOME/src/github.com/doctorondemand"

# Your GitHub username
export GITHUB_USER=

# Your email address
export EMAIL_ADDRESS=

# Your 3 character initials
export INITIALS=

# Your Legacy Grand Rounds username, probably firstname.lastname
export GR_USERNAME=

# The username you have in JIRA.
# As of 11/2021 :
# if your email address is @grandrounds.com or @includedhealth.com,
# your JIRA username is probably "$GR_USERNAME@grandrounds.com"
# if your email address is @doctorondemand, your JIRA username is probably
# your email address
export JIRA_USERNAME=

# This is the default value used to authenticate to AWS resources
# using the aws-environment script. Most people don't need to change this.
export AWS_DEFAULT_ROLE=developer
