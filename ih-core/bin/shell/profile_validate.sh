#!/bin/bash

function validate_profile_env() {

    PROFILE_FILE="$HOME/.ih/profile.sh"

    source $PROFILE_FILE

    VARS="GR_HOME DOD_HOME GITHUB_USER EMAIL_ADDRESS INITIALS GR_USERNAME JIRA_USERNAME AWS_DEFAULT_ROLE"

     status=0
    for name in $VARS; do
        value="${!name}"
        if [[ -z "$value" ]]; then
        echo "$name environment variable must not be empty"
        status=1
        fi
    done

    if [[ $status -ne 0 ]]; then
        echo "Set missing vars in $PROFILE_FILE"
    fi

    return $status
}
