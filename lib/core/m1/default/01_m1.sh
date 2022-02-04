#!/usr/bin/env bash

# Use correct brew and brew path stuff based on shell architecture compatibility
if [[ "$(uname -m)" == 'arm64' ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  eval "$(/usr/local/bin/brew shellenv)"
fi

# Aliases to switch compatibility mode in shells
alias x86='arch -x86_64 $SHELL'
alias amd64='arch -arm64 $SHELL'

alias ibrew='arch -x86_64 /usr/local/bin/brew'
alias mbrew='arch -arm74 /opt/homebrew/bin/brew'
