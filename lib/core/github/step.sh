#!/bin/bash

function ih::setup::core.github::help() {
  echo "Configure github settings

    This step will:
    - Authenticate you to GitHub via the gh CLI tool
    - Configure your GitHub account to support authenticating with your SSH key"
}

function ih::setup::core.github::test() {

  local SSH_RESULT
  SSH_RESULT=$(ssh git@github.com 2>&1)

  if [[ $SSH_RESULT =~ "You've successfully authenticated" ]]; then
    return 0
  fi

  return 1
}

function ih::setup::core.github::deps() {
  # echo "other steps"
  echo "core.shell core.git core.ssh"
}

function ih::setup::core.github::install() {

  # make sure gh is installed
  command -v gh >/dev/null 2>&1 || brew install gh

  echo "You are about to walk through the gh CLI tool auth process.
Please choose:
 authenticate to github.com
 use SSH as preferred protocol
 upload your SSH key
 authenticate with a web browser
 "

  # log in with scopes we need to update keys
  gh auth login --scopes repo,read:org,admin:public_key,user

  local PUBLIC_KEY
  local EXISTING_KEYS
  PUBLIC_KEY=$(cat "$HOME"/.ssh/id_rsa.pub)
  EXISTING_KEYS=$(gh ssh-key list)

  if [[ $EXISTING_KEYS =~ $PUBLIC_KEY ]]; then
    echo "Your SSH key has already been added to GitHub"
  else
    gh ssh-key add "$HOME/.ssh/id_rsa.pub" -t "Included Health"
  fi

  if ih::setup::core.github::test; then
    echo "GitHub configuration complete"

    ih::log::warn "To clone repos from the doctorondemand organization you will need to manually authorize your SSH key"

    ih::ask::confirm "Do you need to authorize your SSH key to clone doctorondemand repos?"
    local CONFIRMED=$?
    if [ $CONFIRMED ]; then
      open "https://github.com/settings/keys"
    fi

    return 0
  fi

  ih::log::error "Github configuration failed, try installing again with -v flag for details"
  return 1

}
