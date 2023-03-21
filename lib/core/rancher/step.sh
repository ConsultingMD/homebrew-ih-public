#!/bin/bash

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.

function ih::setup::core.rancher::help() {
  echo 'Install Rancher Desktop as an alternative to Docker Desktop'
}

# Check if the step has been installed and return 0 if it has.
# Otherwise return 1.
function ih::setup::core.rancher::test() {


    # Check for PLIST FILE
    PLISTFILE="$HOME/Library/Preferences/io.rancherdesktop.profile.defaults.plist"
    if [ -f "$PLISTFILE" ]; then
        return 0
    fi
     

    ih::log::debug "Rancher Desktop is not available"
    return 1
}

function ih::setup::core.rancher::deps() {
  echo "core.shell"
}


function ih::setup::core.rancher::install() {
    local THIS_DIR="$IH_CORE_LIB_DIR/core/rancher"

    cp "${THIS_DIR}/io.rancherdesktop.profile.defaults.plist" "$HOME/Library/Preferences/io.rancherdesktop.profile.defaults.plist"



    CASKSUCCEEDED=1
    # Installation and configuration of Rancher Desktop
    for _ in 1 2 3; do

        # Detect Rosetta
        if [[ $(sysctl -n sysctl.proc_translated) -eq 1 ]]; then
            # Rosetta  Active
            arch -arm64 -c brew reinstall ih-rancher
        else
            brew reinstall ih-rancher
        fi

        CASKSUCCEEDED=$?
        if [ $CASKSUCCEEDED -eq 0 ]; then
            break
        fi
    done

    # EL rm despues del start
    rm -rf ~/.rd
    $(~/../../Applications/Rancher\ Desktop.app/Contents/Resources/resources/darwin/bin/rdctl start)
    # Check for docker binary in /usr/local/bin
    # Check if /usr/local/bin/docker exists
    DOCKERBIN=/usr/local/bin/docker
    DOCKERCOMPOSEBIN=/usr/local/bin/docker-compose
    if [ ! -f "$DOCKERBIN" ]; then

        echo "In order to continue with Rancher configuration and be able to use this engine, some IDEs require the creation of symlinks for remote Python interpreters"
        echo "Your password is required for the creation of symlink mentioned above"
        sudo ln -s $HOME/.rd/bin/docker /usr/local/bin/docker
        if [ ! -f "$DOCKERCOMPOSEBIN" ]; then
            sudo ln -s $HOME/.rd/bin/docker-compose /usr/local/bin/docker-compose
        fi
    fi
    
    echo "Rancher Desktop has been installed successfully"
}
