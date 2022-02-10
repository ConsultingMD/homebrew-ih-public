#!/bin/bash

function ih::setup::core.git::help() {
  echo "Configure git settings

    This step will:
    - Update your global git config to use some good defaults
      This will not overwrite any existing settings that you have set.
    - Create $GR_HOME if it doesn't exist.
    - Create a default global .gitignore if one doesn't exist.
    - Set up pre-commit to install automatically when repos are cloned."

}

function ih::setup::core.git::test() {
  re_source

  if [[ ! -f $HOME/.gitignore_global ]]; then
    ih::log::debug ".gitignore_global not found in $HOME"
    return 1
  fi

  local CONFIGURED_GIT_USER
  CONFIGURED_GIT_USER=$(git config --global user.name)
  if [ -z "$CONFIGURED_GIT_USER" ]; then
    ih::log::debug "git config user.name not set"
    return 1
  fi

  if [[ $(git config --global user.name) != "$GITHUB_USER" ]]; then
    ih::log::warn "git config user.name ($(git config --global user.name)) != GITHUB_USER ($GITHUB_USER), some things may not work correctly"
    return 0
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

  ih::setup::core.git::private::set-if-unset "user.name" "${GITHUB_USER}"
  ih::setup::core.git::private::set-if-unset "user.email" "${GITHUB_EMAIL_ADDRESS}"
  ih::setup::core.git::private::set-if-unset "color.ui" "true"
  ih::setup::core.git::private::set-if-unset "core.excludesfile" "${HOME}/.gitignore_global"
  ih::setup::core.git::private::set-if-unset "push.default" "simple"

  # make git use ssh for everything
  git config --global url.ssh://git@github.com/.insteadOf https://github.com/

  # set up pre-commit to automatically be set up for all cloned repos,
  # if the user doesn't have a templateDir already
  if git config --global init.templateDir; then
    ih::log::warn "Detected existing templateDir, not setting up pre-commit auto-enable."
  else
    local GIT_TEMPLATE_DIR="${IH_DIR}/git-template"
    mkdir "$GIT_TEMPLATE_DIR" 2>/dev/null || :
    git config --global init.templateDir "$GIT_TEMPLATE_DIR"
    pre-commit init-templatedir "$GIT_TEMPLATE_DIR"
  fi

  # Make sure the desired src directory exists if GR_HOME is declared
  [[ -n ${GR_HOME} ]] && mkdir -p "${GR_HOME}"

  # Copy the gitignore template into global if there isn't already a global.
  cp -n "${IH_CORE_LIB_DIR}/core/git/gitignore" "${HOME}/.gitignore_global" || :

  ih::log::info "Updated git global config as follows:"
  git -P config --global --list
  echo ""
}

# sets global config setting $1 to value $2 if it is not currently set
function ih::setup::core.git::private::set-if-unset() {
  git config --global "$1" || git config --global "$1" "$2"
}
