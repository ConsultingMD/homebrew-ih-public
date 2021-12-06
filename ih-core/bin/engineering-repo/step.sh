#!/bin/bash

THIS_DIR=$(dirname $BASH_SOURCE)
IH_DIR="$HOME/.ih"
IH_CUSTOM_DIR="$IH_DIR/custom"

function ih::setup::engineering-repo::help() {
    echo "Clone engineering repo to access additional scripts
    
    This step will:
    - Clone the ConsultingMD/engineering repo"
}

function ih::setup::engineering-repo::test() {
    if [ -d "${GR_HOME}/engineering" ]; then
        return 0
    fi

    return 1
}

function ih::setup::engineering-repo::deps() {
    # echo "other steps"
    echo "github"
}

function ih::setup::engineering-repo::install() {

    mkdir -p "${GR_HOME}"

    git clone git@github.com:ConsultingMD/engineering.git --filter=blob:limit=1m --depth=5 "${GR_HOME}/engineering" 

    echo "Engineering repo cloned"
}