#!/bin/bash

THIS_DIR=$(dirname $BASH_SOURCE)
IH_DIR="$HOME/.ih"
IH_CUSTOM_DIR="$IH_DIR/custom"

function ih::setup::git::help(){
    echo "Configure git settings

    This step will:
    - update your global git config to use some good defaults
    - create $GR_HOME if it doesn't exist
    - create a default global .gitignore if one doesn't exist"
}

function ih::setup::git::test(){

    if [[ ! -f $HOME/.gitignore_global ]]; then
        return 1
    fi

    if [[ $(git config --global user.name) != "$GITHUB_USER" ]]; then
        return 1
    fi

    return 0
}

function ih::setup::git::deps(){
    # echo "other steps"
    echo "shell"
}

function ih::setup::git::install(){

    # Profile must be valid before we can setup git
    ih::setup::shell::private::configure-profile

    git config --global user.name "${GITHUB_USER}"
    git config --global user.email "${EMAIL_ADDRESS}"
    git config --global color.ui true
    git config --global core.excludesfile "${HOME}/.gitignore_global"
    git config --global push.default simple
    git config --global pull.default simple
    git config --global url.ssh://git@github.com/.insteadOf https://github.com/

    #Make sure the desired src directory exists if GR_HOME is declared
    [[ ! -z ${GR_HOME+x} ]] && mkdir -p "${GR_HOME}"

    # Copy the gitignore template into global if there isn't already a global.
    cp -n "${BIN_DIR}/git/gitignore" "${HOME}/.gitignore_global" || :

    echo "Updated git global config as follows:"
    PAGER=cat git config --global --list
    echo ""

    echo "Git configuration completed."

}
