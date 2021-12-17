#!/bin/bash

function ih::setup::core.git::help() {
  echo "Configure git settings

    This step will:
    - update your global git config to use some good defaults
    - create $GR_HOME if it doesn't exist
    - create a default global .gitignore if one doesn't exist"
}

function ih::setup::core.git::test() {
  if [[ ! -f $HOME/.ih/augment.sh ]]; then
    ih::log::debug ".gitignore_global not found in $HOME"
    return 1
  fi

  ih::private::re-source

  if [[ ! -f $HOME/.gitignore_global ]]; then
    ih::log::debug ".gitignore_global not found in $HOME"
    return 1
  fi

  if [[ $(git config --global user.name) != "$GITHUB_USER" ]]; then
    ih::log::debug "git config user.name ($(git config --global user.name)) != GITHUB_USER ($GITHUB_USER)"
    return 1
  fi

  return 0
}

function ih::setup::core.git::deps() {
  # echo "other steps"
  echo "core.shell"
}

function ih::setup::core.git::install() {
  # Profile must be valid before we can setup git
  ih::setup::core.shell::private::configure-profile

  git config --global user.name "${GITHUB_USER}"
  git config --global user.email "${GITHUB_EMAIL_ADDRESS}"
  git config --global color.ui true
  git config --global core.excludesfile "${HOME}/.gitignore_global"
  git config --global push.default simple
  git config --global url.ssh://git@github.com/.insteadOf https://github.com/

  # Make sure the desired src directory exists if GR_HOME is declared
  [[ -n ${GR_HOME} ]] && mkdir -p "${GR_HOME}"

  # Copy the gitignore template into global if there isn't already a global.
  cp -n "${IH_CORE_LIB_DIR}/core/git/gitignore" "${HOME}/.gitignore_global" || :

  echo "Updated git global config as follows:"
  git -P config --global --list
  echo ""

  echo "Git configuration completed."
}
