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

# Prefer to activate the arm64 version of brew if it's available.
# If it is, we don't want to activate the x86 version even if it's installed
# because it will cause a lot of confusion. Really users shouldn't have
# both installed at the same time, but we can't prevent that and
# fixing it is a lot of work if you have packages installed across both.
# Anyone who is actively using both versions on purpose is a power user
# who can figure out how to switch between them.
# For anyone who has both installed by accident we will try to minimize
# the confusion.
#
# eval-ing the brew shellenv command puts the binaries installed by
# that version of brew at the front of the PATH.
if [ -f "/opt/homebrew/bin/brew" ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -f "/usr/local/bin/brew" ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

#Make sure home ~/bin is in the path
[[ ! "$PATH" =~ ${HOME}/bin ]] && export PATH="${HOME}/bin:${PATH}"

# Allow importing of private repos in GO
export GOPRIVATE="github.com/ConsultingMD/*"

# Allow installing gems from a proxy that automatically authenticates when on the internal network
export BUNDLE_MIRROR__GEM__FURY__IO="https://gems.includedhealth.com/doctorondemand/"
