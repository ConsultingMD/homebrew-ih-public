#!/bin/bash

# This is a place for you to create custom bash functions and aliases
# It will not be overwritten when the core bootstrapping
# module is updated

# Only continue if we're on bash
SHELL=$(ps -cp "$$" -o command="")
if [[ ! $SHELL =~ "bash" ]]; then
  return 0
fi
