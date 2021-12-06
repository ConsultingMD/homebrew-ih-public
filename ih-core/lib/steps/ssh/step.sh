#!/bin/bash

function ih::setup::ssh::help() {
    local SSH_CONFIG_PATH=$HOME/.ssh/config

    echo "Configure SSH settings

    - Check that you have an SSH key and create one if you don't
    - Create a file at $SSH_CONFIG_PATH which will default SSH to using your key"
}

function ih::setup::ssh::test() {

    if [[ ! -f $HOME/.ssh/config ]]; then
        ih::log::debug "No SSH config found"
        return 1
    fi
    ih::log::debug "SSH config found"
    if [[ ! -f "$HOME/.ssh/id_rsa.pub" ]]; then
        ih::log::debug "No SSH default key found (id_rsa.pub)"
        return 1
    fi

    ih::log::debug "SSH default key found (id_rsa.pub)"

    if [[ "$(ssh-keygen -lf "$HOME/.ssh/id_rsa" | cut -d' ' -f1)" == "4096" ]]; then
        ih::log::debug "SSH default key is 4096"
        return 0
    else
        ih::log::debug "SSH default key is not 4096 RSA"
        return 1
    fi
}

function ih::setup::ssh::deps() {
    # echo "other steps"
    echo "shell"
}

function ih::setup::ssh::install() {

    local SSH_CONFIG_PATH=$HOME/.ssh/config

    mkdir -p "$HOME"/.ssh

    set -e
    cp -n "${IH_CORE_LIB_DIR}/steps/ssh/sshconfig" "${SSH_CONFIG_PATH}" || :
    set +e

    eval "$(ssh-agent -s)"

    if [[ ! -e $HOME/.ssh/id_rsa ]]; then
        ssh-keygen -f "$HOME/.ssh/id_rsa" -b4096 -t rsa -C "${EMAIL_ADDRESS}"
        ssh-add -K "$HOME/.ssh/id_rsa"
    else
        # make sure there's a public key file because
        # ssh-keygen -l doesn't decrypt encrypted private keys
        if [[ ! -e $HOME/.ssh/id_rsa.pub ]]; then
            ssh-keygen -f "$HOME/.ssh/id_rsa" -y >"$HOME/.ssh/id_rsa.pub"
        fi

        if [[ "$(ssh-keygen -lf "$HOME/.ssh/id_rsa" | cut -d' ' -f1)" == "4096" ]]; then
            echo "Excellent - you have a 4k ssh key created and installed"
            eval "$(ssh-agent -s)"
            ssh-add -K "$HOME/.ssh/id_rsa"
        else
            echo "Uh-oh. you have an existing ssh key, but it doesn't appear to be a 4k RSA key."
            echo "Contact an adult for help in resolving this."
        fi
    fi
    echo ""
    echo "SSH configuration completed."

}
