#!/bin/bash

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.

function ih::setup::core.rancher::help() {
  echo 'Install Rancher Desktop as an alternative to Docker Desktop'
}

# Check if the step has been installed and return 0 if it has.
# Otherwise return 1.
function ih::setup::core.rancher::test() {

    # Check if .rd directory exists as well as rdctl and docker command
    if command -v rdctl  &&  command -v docker && [ -d "$HOME/.rd/bin" ] ; then
        ih::log::debug "Rancher Desktop is not available"
        return 1
    else
        return 0
    fi

}

function ih::setup::core.rancher::deps() {
  echo "core.shell"
}


function ih::setup::core.rancher::install() {
    CASKSUCCEEDED=1
    # Installation and configuration of Rancher Desktop
    for _ in 1 2 3; do
        brew install ih-rancher 
        CASKSUCCEEDED=$?
        if [ $CASKSUCCEEDED -eq 0 ]; then
            # Disable kubernetes by default. 
            # More information: https://docs.rancherdesktop.io/references/rdctl-command-reference/#rdctl-set
            # Rancher Desktop has to be running in order to disable Kubernetes
            rdctl start --container-engine moby &
            echo "Starting Rancher"
            while :
            do	
                sleep 5
                rdctl set --kubernetes-enabled=false > /dev/null 2>&1
                PREV=$?
                if [[ $PREV -eq 0 ]]; then
                    echo "Rancher Desktop will use dockerd as the container engine and Kubernetes will be disabled by default"
                    break
                fi
                echo "Rancher still starting up"
            done

            break
        fi
    done

    # Check for docker binary in /usr/local/bin
    # Check if /usr/local/bin/docker exists
    DOCKERBIN=/usr/local/bin/docker
    DOCKERCOMPOSEBIN=/usr/local/bin/docker-compose
    if [ ! -f "$DOCKERBIN" ]; then

        echo "In order to continue with Rancher configuration and be able to use this engine, some IDEs require the creation of symlinks for remote Python interpreters"
        echo "Your password is required for the creation of symlink mentioned above"
        sudo ln -s $(which docker) /usr/local/bin/docker
        if [ ! -f "$DOCKERCOMPOSEBIN" ]; then
            sudo ln -s $(which docker-compose) /usr/local/bin/docker-compose
        fi
    fi
    
    echo "Rancher Desktop has been installed successfully"
}
