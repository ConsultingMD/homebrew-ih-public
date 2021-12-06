#!/bin/bash

# Steps will have IH_CORE_DIR set to the directory containing the bin and lib directories.

function ih::setup::NAME::help(){
    echo "Summary line about this step

    This step will:
        - detail
        - detail
    "
}

# Check if the step has been installed and return 0 if it has.
# Otherwise return 1.
function ih::setup::NAME::test(){
    echo "Step already installed"
    return 0
}

# Echo a space-delimited list of steps which must be installed before this one can be.
function ih::setup::NAME::deps(){
    # echo "step1 step2"
    echo ""
}

function ih::setup::NAME::install(){
    echo "Installing"
}
