#!/bin/bash

# This file defines the common environment variables
# which the Platform team has found to be useful.
# You can override thes values in the env_custom.sh file.

# ██████╗  ██████╗     ███╗   ██╗ ██████╗ ████████╗    ███████╗██████╗ ██╗████████╗
# ██╔══██╗██╔═══██╗    ████╗  ██║██╔═══██╗╚══██╔══╝    ██╔════╝██╔══██╗██║╚══██╔══╝
# ██║  ██║██║   ██║    ██╔██╗ ██║██║   ██║   ██║       █████╗  ██║  ██║██║   ██║
# ██║  ██║██║   ██║    ██║╚██╗██║██║   ██║   ██║       ██╔══╝  ██║  ██║██║   ██║
# ██████╔╝╚██████╔╝    ██║ ╚████║╚██████╔╝   ██║       ███████╗██████╔╝██║   ██║
# ╚═════╝  ╚═════╝     ╚═╝  ╚═══╝ ╚═════╝    ╚═╝       ╚══════╝╚═════╝ ╚═╝   ╚═╝
# Changes to this file will be overwritten if you update the ih-core formula

# Signals that IH shell augments have been sourced
export IH_AUGMENT_SOURCED=yes

# Use correct brew and brew path stuff based on shell architecture compatibility
if [[ "$(uname -m)" == 'arm64' ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  eval "$(/usr/local/bin/brew shellenv)"
fi

#Make sure home ~/bin is in the path
[[ ! "$PATH" =~ ${HOME}/bin ]] && export PATH="${HOME}/bin:${PATH}"

# Allow importing of private repos in GO
export GOPRIVATE="github.com/ConsultingMD/*"
