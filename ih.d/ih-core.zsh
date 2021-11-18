#!/bin/zsh

for f in "$(brew --prefix ih-core)/scripts/*"; do
  # this sets up aws-environment, vault-token and more.
  . "$f"
done