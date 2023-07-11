#!/bin/bash

# This file defines the common environment variables
# which the Platform team has found to be useful.
# You can override these values in the env_custom.sh file.

# ██████╗  ██████╗     ███╗   ██╗ ██████╗ ████████╗    ███████╗██████╗ ██╗████████╗
# ██╔══██╗██╔═══██╗    ████╗  ██║██╔═══██╗╚══██╔══╝    ██╔════╝██╔══██╗██║╚══██╔══╝
# ██║  ██║██║   ██║    ██╔██╗ ██║██║   ██║   ██║       █████╗  ██║  ██║██║   ██║
# ██║  ██║██║   ██║    ██║╚██╗██║██║   ██║   ██║       ██╔══╝  ██║  ██║██║   ██║
# ██████╔╝╚██████╔╝    ██║ ╚████║╚██████╔╝   ██║       ███████╗██████╔╝██║   ██║
# ╚═════╝  ╚═════╝     ╚═╝  ╚═══╝ ╚═════╝    ╚═╝       ╚══════╝╚═════╝ ╚═╝   ╚═╝
# Changes to this file will be overwritten if you update the ih-core formula

# Signals that IH shell augments have been sourced
export IH_AUGMENT_SOURCED=yes

# Activate brew paths
[ -f "/usr/local/bin/brew" ] && eval "$(/usr/local/bin/brew shellenv)"

#Make sure home ~/bin is in the path
[[ ! "$PATH" =~ ${HOME}/bin ]] && export PATH="${HOME}/bin:${PATH}"

# Allow importing of private repos in GO
export GOPRIVATE="github.com/ConsultingMD/*"

# Allow installing gems from a proxy that automatically authenticates when on the internal network
export BUNDLE_MIRROR__GEM__FURY__IO="https://gems.includedhealth.com/doctorondemand/"
