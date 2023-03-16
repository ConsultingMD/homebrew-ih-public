#!/bin/bash

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.

function ih::setup::core.rancher::help() {
  echo 'Install Rancher Desktop as an alternative to Docker Desktop'
}

# Check if the step has been installed and return 0 if it has.
# Otherwise return 1.
function ih::setup::core.rancher::test() {

    if command -v rdctl; then
        echo "Rancher Desktop has been installed successfully"
        return 0
    else
        echo "Install Rancher Desktop failed. Please contact platform support
    in the #developer-platform-support channel in Slack (https://ih-epdd.slack.com/archives/C03GXCDA48Y)."
        return 1
    fi
}

function ih::setup::core.rancher::deps() {
  echo "core.shell"
}


function ih::setup::core.rancher::install() {
    CASKSUCCEEDED=1
    for _ in 1 2 3; do
        brew install ih-rancher 
        CASKSUCCEEDED=$?
        if [ $CASKSUCCEEDED -eq 0 ]; then
            # Disable kubernetes by default. 
            # More information: https://docs.rancherdesktop.io/references/rdctl-command-reference/#rdctl-set
            rdctl set --kubernetes-enabled=false
            break
        fi
    done
}
