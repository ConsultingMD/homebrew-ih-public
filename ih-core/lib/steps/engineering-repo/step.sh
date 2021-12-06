#!/bin/bash

function ih::setup::engineering-repo::help() {
  echo "Clone engineering repo to access additional scripts

    This step will:
    - Clone the ConsultingMD/engineering repo"
}

function ih::setup::engineering-repo::test() {
  if [ -d "${GR_HOME}/engineering" ]; then
    return 0
  fi

  return 1
}

function ih::setup::engineering-repo::deps() {
  # echo "other steps"
  echo "github"
}

function ih::setup::engineering-repo::install() {

  mkdir -p "${GR_HOME}"

  if [ -d "${GR_HOME}/engineering" ]; then
    ih::log::error "The destination folder ${GR_HOME}/engineering already exists"
    return 1
  fi

  git clone git@github.com:ConsultingMD/engineering.git --filter=blob:limit=1m --depth=5 "${GR_HOME}/engineering"

  if [[ $? -ne 1 ]]; then
    return 1
  fi

  ih::log::info "Engineering repo cloned"
  ih::log::warn "You should source .zshrc or .bashrc to ensure the engineering scripts are loaded (or start a new shell)"
}