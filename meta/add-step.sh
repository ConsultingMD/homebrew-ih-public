#!/bin/bash


STEP=${1:?"You must provide a name for your new step"}

THIS_DIR=$(dirname $(realpath "$0"))
BIN_DIR="$THIS_DIR/../ih-core/bin"

STEP_DIR="$BIN_DIR/$STEP"

if [[ -d $STEP_DIR ]]; then
    echo "A step named $STEP already exists" 
    return 1
fi

mkdir -p "$STEP_DIR"
# shellcheck disable=SC2016
echo "#!/bin/bash

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.

function ih::setup::$STEP::help(){
    echo 'Summary line about this step

    This step will:
        - detail
        - detail
    '
}

# Check if the step has been installed and return 0 if it has.
# Otherwise return 1.
function ih::setup::$STEP::test(){
    echo "Step installed"
    return 0
}

# Echo a space-delimited list of steps which must be installed before this one can be.
function ih::setup::$STEP::deps(){
    # echo "step1 step2"
    echo ""
}

function ih::setup::$STEP::install(){
    echo 'Installing...'
}
" > "$STEP_DIR/step.sh"