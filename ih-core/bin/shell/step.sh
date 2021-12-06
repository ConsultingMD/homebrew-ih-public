#!/bin/bash

IH_DIR="$HOME/.ih"
IH_CUSTOM_DIR="$IH_DIR/custom"

function ih::setup::shell::help(){
    echo "Augment shell with Included Health components

    This step will:
    - Copy the augment.sh shell setup scripts into $HOME/.ih
      and source it in .zshrc and .bashrc. This script sources
      additional scripts that are used for engineering work.
    - Create some convential files where you can customize aliases
      and other shell things (if those files don't already exist)
    - Give you a chance to fill out some environment variables
      with your personal information (if you haven't done this yet)."
}

function ih::setup::shell::test(){

    env | grep IH

    ih::log::debug "Checking for shell augment files and variables..."
    if [[ -f "${IH_DIR}/augment.sh" ]]; then
        ih::log::debug "Found augment.sh"
        if [[ -z $IH_AUGMENT_SOURCED ]]; then
            ih::log::warn "Shell augments are installed but not sourced; source .zshrc or .bashrc to load them"
            source "${IH_DIR}/augment.sh"
            return 0
        else 
            ih::setup::shell::private::validate-profile
            return $?
        fi
    else 
        ih::log::debug "Augment file not found"
        return 1
    fi

}

function ih::setup::shell::deps(){
    # echo "other steps"
    echo ""
}

function ih::setup::shell::install(){

    local THIS_DIR="$IH_CORE_DIR/bin/shell"

    echo "Copying shell augmentation templates to ${IH_DIR}"

    mkdir -p "$IH_DIR"
    cp -rn "${THIS_DIR}/custom/" "${IH_DIR}/custom" || :
    cp -R "${THIS_DIR}/default/" "${IH_DIR}/default"
    cp "${THIS_DIR}/augment.sh" "${IH_DIR}/augment.sh"

    ih::setup::shell::private::configure-profile

    echo "Configuring shells to source IH shell configs"

    ih::setup::shell::private::configure-bashrc
    ih::setup::shell::private::configure-zshrc

    echo ""

    re_source

    echo "Shell configuration complete. When you start a new shell you'll have all the Included Health scripts available."


}


# shellcheck disable=SC2016
BOOTSTRAP_SOURCE_LINE='
# This loads the Included Health shell augmentations into your interactive shell
. $HOME/.ih/augment.sh
'

# Create bashrc if it doesn't exist, if it does, append standard template
function ih::setup::shell::private::configure-bashrc() {
    if [[ ! -e "${HOME}/.bashrc" ]]; then
        echo "Creating new ~/.bashrc file"
        touch "${HOME}/.bashrc"
    fi
    # shellcheck disable=SC2016
    if grep -qF '. $HOME/.ih/augment.sh' "${HOME}/.bashrc"; then
        echo "Included Health shell augmentation already sourced in .bashrc"
    else 
        echo "Appending Included Health config to .bashrc"
        # shellcheck disable=SC2016
        echo "$BOOTSTRAP_SOURCE_LINE">> "${HOME}/.bashrc"


    echo "Updated .bashrc to include this line at the end:

$BOOTSTRAP_SOURCE_LINE

If you want to source IH scripts earlier, adjust your .bashrc"
    fi

}

# Create zshrc if it doesn't exist, if it does, append standard template
function ih::setup::shell::private::configure-zshrc() {
    if [[ ! -e "${HOME}/.zshrc" ]]; then
        echo "Creating new ~/.zshrc file"
        touch "${HOME}/.zshrc"
    fi

    # shellcheck disable=SC2016
    if grep -qF '. $HOME/.ih/augment.sh' "${HOME}/.zshrc"; then
        echo "Included Health shell augmentation already sourced in .zshrc"
    else 
        echo "Appending Included Health config to .zshrc"
        echo "$BOOTSTRAP_SOURCE_LINE" >> "${HOME}/.zshrc"
        echo "Updated .zshrc to include this line at the end:

$BOOTSTRAP_SOURCE_LINE

If you want to source IH scripts earlier, adjust your .zshrc"
    fi
}



function ih::setup::shell::private::configure-profile(){

    re_source

    ih::setup::shell::private::validate-profile
    local PROFILE_VALID=$?
    local PROFILE_FILE="$IH_CUSTOM_DIR"/00_env.sh

    if [[ $PROFILE_VALID -ne 0 ]]; then 
        ih::private::confirm "Your profile environment variables are not set up. Ready to edit and update your variables?"
        confirm_edit=$?
        if [[ ${confirm_edit} -ne 0 ]]; then
            # shellcheck disable=SC2263
            echo "You can't continue bootstrapping until you've updated your environment variables."
            # shellcheck disable=SC2263
            echo "You can manually edit ${PROFILE_FILE} and re-run the script."
            exit 1
        fi

        nano "$PROFILE_FILE"

        ih::setup::shell::private::configure-profile
    fi

    re_source
}

# Source all appropriate files for to refresh the shell
function re_source() {
    exec 3> /dev/stderr 2> /dev/null
    exec 4> /dev/stdout 1> /dev/null

    echo "Sourcing recently updated files."

    local BOOTSTRAP_FILE="$IH_DIR"/augment.sh
    source "$BOOTSTRAP_FILE"

    exec 2>&3
    exec 1>&4
}



function ih::setup::shell::private::validate-profile() {

    local PROFILE_FILE="$IH_CUSTOM_DIR/00_env.sh"
    local PROFILE_TEMPLATE_FILE="$IH_CORE_DIR/bin/shell/custom/00_env.sh"

    if [[ ! -f $PROFILE_FILE ]]; then 
        return 1
    fi

    set -e
    local VARS=$(cat $PROFILE_TEMPLATE_FILE | grep export | cut -f 2 -d" " - | cut -f 1 -d"=" -)

    source $PROFILE_FILE

    set +e

    status=0
    for name in $VARS; do
        value="${!name}"
        if [[ -z "$value" ]]; then
        ih::log::debug "$name environment variable must not be empty"
        status=1
        fi
    done

    if [[ $status -ne 0 ]]; then
        ih::log::warn "Set missing vars in $PROFILE_FILE"
    fi

    return $status
}
