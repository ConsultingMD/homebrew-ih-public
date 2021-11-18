
# Directory where you want to clone Legacy Grand Rounds repos,
# which are currently located in the ConsultingMD org.
export GR_HOME="$HOME/src/github.com/ConsultingMD/"

# Your GitHub username
export GITHUB_USER=""

# Your Legacy Grand Rounds username, probably firstname.lastname
export GR_USERNAME=""

# The username you have in JIRA. 
# As of 11/2021 :
# if your email address is @grandrounds.com or @includedhealth.com,
# your JIRA username is probably "$GR_USERNAME@grandrounds.com"
# if your email address is @doctorondemand, your JIRA username is probably
# your email address 
export JIRA_USERNAME=""

# This is the default value used to authenticate to AWS resources
# using the aws-environment script. Most people don't need to change this.
export AWS_DEFAULT_ROLE=developer