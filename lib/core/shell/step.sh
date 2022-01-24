#!/bin/bash

function ih::setup::core.shell::help() {
  echo "Augment shell with Included Health components

    This step will:
    - Copy the augment.sh shell setup scripts into $HOME/.ih
      and source it in .zshrc and .bashrc. This script sources
      additional scripts that are used for engineering work.
    - Create some conventional files where you can customize aliases
      and other shell things (if those files don't already exist)
    - Give you a chance to fill out some environment variables
      with your personal information (if you haven't done this yet)."
}

function ih::setup::core.shell::test() {

  ih::log::debug "Checking for shell augment files and variables..."
  if ! ih::setup::core.shell::private::validate-profile; then
    ih::log::debug "Profile is not valid"
    return 1
  fi

  if [[ -f "${IH_DIR}/augment.sh" ]]; then
    ih::log::debug "Found augment.sh"
    if [[ -z $IH_AUGMENT_SOURCED ]]; then
      ih::log::warn "Shell augments are installed but not sourced; source .zshrc or .bashrc to load them"
      source "${IH_DIR}/augment.sh"
    fi

    return 0
  else
    ih::log::debug "Augment file not found"
    return 1
  fi

  local DEFAULT_SRC_DIR="${IH_CORE_LIB_DIR}/core/shell/default"
  local DEFAULT_DST_DIR="${IH_HOME}/default"

  for DEFAULT_SRC in "$DEFAULT_SRC_DIR"/*; do
    local DEFAULT_DST="$DEFAULT_DST_DIR/${DEFAULT_SRC/$DEFAULT_SRC_DIR/}"
    if [ -f "$DEFAULT_DST" ]; then
      ih::log::debug "File $DEFAULT_DST not found."
      return 1
    fi

    if [[ $(diff -q "$DEFAULT_DST" "$DEFAULT_SRC" >/dev/null) -ne 0 ]]; then
      ih::log::debug "File $DEFAULT_DST does not match source"
      return 1
    fi
  done

  return 0
}

function ih::setup::core.shell::deps() {
  # echo "other steps"
  echo ""
}

function ih::setup::core.shell::install() {

  local THIS_DIR="$IH_CORE_LIB_DIR/core/shell"

  echo "Copying shell augmentation templates to ${IH_DIR}"

  mkdir -p "$IH_DIR"
  cp -rn "${THIS_DIR}/custom/" "${IH_DIR}/custom" || :
  chmod 0700 "${IH_DIR}/custom"
  chmod 0600 "${IH_DIR}"/custom/*
  cp -r "${THIS_DIR}/default/" "${IH_DIR}/default"
  chmod 0700 "${IH_DIR}/default"
  chmod 0600 "${IH_DIR}"/default/*
  cp "${THIS_DIR}/augment.sh" "${IH_DIR}/augment.sh"

  ih::setup::core.shell::private::configure-profile

  echo "Configuring shells to source IH shell configs"

  ih::setup::core.shell::private::configure-bashrc
  ih::setup::core.shell::private::configure-zshrc

  echo ""

  re_source

  green "Shell configuration complete. When you start a new shell you'll have all the Included Health scripts available."

}

# shellcheck disable=SC2016
BOOTSTRAP_SOURCE_LINE='
# This loads the Included Health shell augmentations into your interactive shell
. "$HOME/.ih/augment.sh"
'

# Create bashrc if it doesn't exist, if it does, append standard template
function ih::setup::core.shell::private::configure-bashrc() {
  if [[ ! -e "${HOME}/.bashrc" ]]; then
    echo "Creating new ~/.bashrc file"
    touch "${HOME}/.bashrc"
  fi
  # shellcheck disable=SC2016
  if grep -qF -E '^[^#]+\.ih/augment.sh' "${HOME}/.bashrc"; then
    echo "Included Health shell augmentation already sourced in .bashrc"
  else
    echo "Appending Included Health config to .bashrc"
    # shellcheck disable=SC2016
    echo "$BOOTSTRAP_SOURCE_LINE" >>"${HOME}/.bashrc"

    echo "Updated .bashrc to include this line at the end:

$BOOTSTRAP_SOURCE_LINE

If you want to source IH scripts earlier, adjust your .bashrc"
  fi

}

# Create zshrc if it doesn't exist, if it does, append standard template
function ih::setup::core.shell::private::configure-zshrc() {
  if [[ ! -e "${HOME}/.zshrc" ]]; then
    echo "Creating new ~/.zshrc file"
    touch "${HOME}/.zshrc"
  fi

  # apply fix to support brew completions in zsh: https://docs.brew.sh/Shell-Completion#configuring-completions-in-zsh
  chmod -R go-w "$(brew --prefix)/share"

  # shellcheck disable=SC2016
  if grep -qF -E '^[^#]+\.ih/augment.sh' "${HOME}/.zshrc"; then
    echo "Included Health shell augmentation already sourced in .zshrc"
  else
    echo "Appending Included Health config to .zshrc"
    echo "$BOOTSTRAP_SOURCE_LINE" >>"${HOME}/.zshrc"
    echo "Updated .zshrc to include this line at the end:

$BOOTSTRAP_SOURCE_LINE

If you want to source IH scripts earlier, adjust your .zshrc"
  fi
}

function ih::setup::core.shell::private::configure-profile() {

  re_source

  ih::setup::core.shell::private::validate-profile
  local PROFILE_VALID=$?
  local PROFILE_FILE="$IH_CUSTOM_DIR"/00_env.sh

  if [[ $PROFILE_VALID -ne 0 ]]; then
    ih::ask::confirm "Your profile environment variables are not set up. Ready to edit and update your variables?"
    confirm_edit=$?
    if [[ ${confirm_edit} -ne 0 ]]; then
      # shellcheck disable=SC2263
      echo "You can't continue bootstrapping until you've updated your environment variables."
      # shellcheck disable=SC2263
      echo "You can manually edit ${PROFILE_FILE} and re-run the script."
      exit 1
    fi

    if [ -z "$EDITOR" ]; then
      read -r -p "Your EDITOR is unset. What editor do you like to use? (maybe enter vim or nano, or 'code -w' to use VSCode): " EDITOR
      export EDITOR
      echo "
export EDITOR=\"$EDITOR\"" >>"$PROFILE_FILE"
    fi

    if ! ${EDITOR} "$PROFILE_FILE"; then
      ih::log::error "It looks like your edit failed, you may want to exit and fix any errors you see above."
      if ih::ask::confirm "Do you want to cancel install"; then
        exit 0
      fi
    fi

    ih::setup::core.shell::private::configure-profile
  fi

  re_source
}

# Source all appropriate files for to refresh the shell
function re_source() {
  exec 3>/dev/stderr 2>/dev/null
  exec 4>/dev/stdout 1>/dev/null

  local BOOTSTRAP_FILE="$IH_DIR"/augment.sh
  # shellcheck disable=SC1090
  source "$BOOTSTRAP_FILE"

  exec 2>&3
  exec 1>&4
}

function ih::setup::core.shell::private::validate-profile() {

  re_source

  local PROFILE_FILE="$IH_CUSTOM_DIR/00_env.sh"
  local PROFILE_TEMPLATE_FILE="$IH_CORE_LIB_DIR/core/shell/custom/00_env.sh"

  if [[ ! -f $PROFILE_FILE ]]; then
    ih::log::debug "Profile file not found at $PROFILE_FILE"
    return 1
  fi
  ih::log::debug "Profile file found at $PROFILE_FILE"

  set -e
  local VARS
  VARS=$(grep export "$PROFILE_TEMPLATE_FILE" | cut -f 2 -d" " - | cut -f 1 -d"=" -)

  # shellcheck disable=SC1090
  source "$PROFILE_FILE"

  set +e

  status=0
  for name in $VARS; do
    value="${!name}"
    if [[ -z "$value" ]]; then
      ih::log::warn "$name environment variable must not be empty"
      status=1
    fi
  done

  if [[ $status -ne 0 ]]; then
    ih::log::warn "Set missing vars in $PROFILE_FILE"
  fi

  return $status
}
