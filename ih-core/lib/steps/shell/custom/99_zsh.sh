#!/bin/bash
# Shebang indicates bash to enable shellcheck

# This is a place for you to create custom aliases for zsh
# It will not be overwritten when the ih-core bootstrapping
# formula is updated

# Only continue if we're on zsh
SHELL=$(ps -cp "$$" -o command="")
if [[ ! $SHELL =~ "zsh" ]]; then
  return 0
fi
