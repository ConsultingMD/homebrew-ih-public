#!/bin/zsh

# This script is the entry point for wiring ih tools and 
# environment config into the shell environment. 
# The bootstrap.sh script will add a line to source this script
# to the user's .zshrc.

for f in "$HOME/ih.d/*"; do
  # this sets up aws-environment, vault-token and more.
  . "$f"
done

for f in "$(brew --prefix ih-core)/scripts/*"; do
  # this sets up aws-environment, vault-token and more.
  . "$f"
done