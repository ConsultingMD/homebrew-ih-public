#!/bin/bash

THIS_DIR=$(dirname $BASH_SOURCE)
IH_DIR="$HOME/.ih"
IH_CUSTOM_DIR="$IH_DIR/custom"

function ih::setup::github::help(){
    echo "Configure github settings
    
    This step will:
    - Authenticate you to GitHub via the gh CLI tool
    - Configure your GitHub account to support authenticating with your SSH key"
}

function ih::setup::github::test(){

    local SSH_RESULT
    SSH_RESULT=$(ssh git@github.com 2>&1)
    
    if [[ $SSH_RESULT =~ "You've successfully authenticated" ]]; then
        return 0
    fi

    return 1
}

function ih::setup::github::deps(){
    # echo "other steps"
    echo "shell git ssh"
}

function ih::setup::github::install(){

    # make sure gh is installed
    command -v gh >/dev/null 2>&1 || brew install gh

    # log in with scopes we need to update keys
    gh auth login --scopes repo,read:org,admin:public_key,user

    local PUBLIC_KEY
    local EXISTING_KEYS
    PUBLIC_KEY=$(cat "$HOME"/.ssh/id_rsa.pub)
    EXISTING_KEYS=$(gh ssh-key list)

    if [[ $EXISTING_KEYS =~ $PUBLIC_KEY ]]; then 
        echo "Your SSH key has already been added to GitHub"
    else 
        gh ssh-key add "$HOME/.ssh/id_rsa.pub" -t "Included Health"
    fi

    ssh git@github.com

    echo ""

    print_header "Cloning the Engineering repo now that we have access"
    mkdir -p "${GR_HOME}"
    pushd "${GR_HOME}" >/dev/null 2>&1 || exit 1
        echo -e "\n* Cloning Engineering repo to ${GR_HOME}, this will take a while..."
            if [ ! -d "${GR_HOME}/engineering" ]; then
                git clone git@github.com:ConsultingMD/engineering.git --filter=blob:limit=1m --depth=5 || { echo -e "${git_clone_err_msg}"; skipped_items_list+=("do_clone_repos:::engineering"); true; }
            else
                echo "Skipping git clone for engineering repo -- ${GR_HOME}/engineering already exists"
            fi
    popd >/dev/null 2>&1 || exit 1

    re_source

    echo ""
    echo "GitHub configuration complete"
}
