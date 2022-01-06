#!/bin/bash

function ih::setup::core.ssh::help() {
  local SSH_CONFIG_PATH=$HOME/.ssh/config

  echo "Configure SSH settings

    - Check that you have an SSH key and create one if you don't
    - Create a file at $SSH_CONFIG_PATH which will default SSH to using your key"
}

function ih::setup::core.ssh::test() {

  if [[ ! -f $HOME/.ssh/config ]]; then
    ih::log::debug "No SSH config found"
    return 1
  fi
  ih::log::debug "SSH config found"
  if [[ ! -f "$HOME/.ssh/id_rsa.pub" ]]; then
    ih::log::debug "No SSH default key found (id_rsa.pub)"
    return 1
  fi

  ih::log::debug "SSH default key found (id_rsa.pub)"

  if [[ "$(ssh-keygen -lf "$HOME/.ssh/id_rsa" | cut -d' ' -f1)" == "4096" ]]; then
    ih::log::debug "SSH default key is 4096"
    return 0
  else
    ih::log::debug "SSH default key is not 4096 RSA"
    return 1
  fi
}

function ih::setup::core.ssh::deps() {
  # echo "other steps"
  echo "core.shell"
}

function ih::setup::core.ssh::install() {

  local SSH_CONFIG_PATH=$HOME/.ssh/config

  mkdir -p "$HOME"/.ssh

  set -e
  cp -n "${IH_CORE_LIB_DIR}/core/ssh/sshconfig" "${SSH_CONFIG_PATH}" || :
  set +e

  eval "$(ssh-agent -s)"

  if [[ ! -e $HOME/.ssh/id_rsa ]]; then
    ih::setup::core.ssh::private::create-ssh-key
  else
    set -eo pipefail
    # set correct permissions so ssh-* won't reject the key
    chmod 0600 "$HOME/.ssh/id_rsa"
    # make sure there's a public key file because
    # ssh-keygen -l doesn't decrypt encrypted private keys
    if [[ ! -e $HOME/.ssh/id_rsa.pub ]]; then
      ssh-keygen -f "$HOME/.ssh/id_rsa" -y >"$HOME/.ssh/id_rsa.pub"
    fi

    if [[ $(ssh-keygen -lf "$HOME/.ssh/id_rsa" | cut -d' ' -f1) == "4096" ]]; then
      echo "Excellent - you have a 4k ssh key created and installed"
      eval "$(ssh-agent -s)"
      ssh-add -K "$HOME/.ssh/id_rsa"
    else
      ih::log::warn "Uh-oh. you have an existing ssh key, but it doesn't appear to be a 4k RSA key."
      if ih::ask::confirm "I want to back up your existing key and create a new one."; then
        mv "$HOME"/.ssh/id_rsa "$HOME"/.ssh/id_rsa.old
        mv "$HOME"/.ssh/id_rsa.pub "$HOME"/.ssh/id_rsa.pub.old

        ih::log::info "Renamed $HOME/.ssh/id_rsa to $HOME/.ssh/id_rsa.old and $HOME/.ssh/id_rsa.pub to $HOME/.ssh/id_rsa.pub.old"

        ih::setup::core.ssh::private::create-ssh-key

      else
        ih::log::warn "Leaving your key alone, you may not be able to authenticate to github correctly."

      fi
    fi
  fi
  set +e
  echo ""
  echo "SSH configuration completed."

}

function ih::setup::core.ssh::private::create-ssh-key() {
  ih::log::info "Creating a new SSH key, make sure you save the password in LastPass or something similar"
  ssh-keygen -f "$HOME/.ssh/id_rsa" -b4096 -t rsa -C "${EMAIL_ADDRESS}"
  ssh-add -K "$HOME/.ssh/id_rsa"
}
