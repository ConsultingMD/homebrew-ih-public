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

# Make sure that /usr/local/bin is in the path,
# so brew will work.
[[ ! "$PATH" =~ "/usr/local/bin" ]] && PATH="/usr/local/bin:$PATH"

#Make sure home ~/bin is in the path
[[ ! "$PATH" =~ ${HOME}/bin ]] && export PATH="${HOME}/bin:${PATH}"
