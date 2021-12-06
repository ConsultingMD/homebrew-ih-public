#!/bin/bash

# This file wires in the scripts which are defined in the 
# ConsultingMD/engineering repo so that the scripts and functions
# are available in your shell.

ENGINEERING_DIR=${GR_HOME}/engineering
ENGINEERING_BIN=${ENGINEERING_DIR}/bin
ENGINEERING_BASH=${ENGINEERING_DIR}/bash

if [[ -d "${ENGINEERING_BASH}" ]]; then

    #Make sure engineering bin is in the path
    if [[ ! "$PATH" =~ ${ENGINEERING_BIN} ]]; then 
        export PATH="${ENGINEERING_BIN}:${PATH}"
    fi

    # this sets up aws-environment, vault-token and more.
    for f in "$ENGINEERING_BASH"/*; do
        # shellcheck source=/dev/null
        . "$f"
    done
fi