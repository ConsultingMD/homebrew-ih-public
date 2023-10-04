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
  else
    ih::log::debug "Augment file not found"
    return 1
  fi

  if ! grep -q -e "augment.sh" ~/.bashrc; then
    ih::log::debug "Augment not sourced in .bashrc"
    return 1
  fi

  if ! grep -q -e "augment.sh" ~/.zshrc; then
    ih::log::debug "Augment not sourced in .zshrc"
    return 1
  fi

  local DEFAULT_SRC_DIR="${IH_CORE_LIB_DIR}/core/shell/default"
  local DEFAULT_DST_DIR="${IH_DIR}/default"

  for DEFAULT_SRC in "$DEFAULT_SRC_DIR"/*; do
    local DEFAULT_DST="${DEFAULT_SRC/$DEFAULT_SRC_DIR/$DEFAULT_DST_DIR}"
    if [ ! -f "$DEFAULT_DST" ]; then
      ih::log::debug "File $DEFAULT_DST not found."
      return 1
    fi

    if ! diff -q "$DEFAULT_DST" "$DEFAULT_SRC" >/dev/null; then
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
  chmod 0600 "${IH_DIR}"/augment.sh

  ih::setup::core.shell::private::configure-profile

  echo "Configuring shells to source IH shell configs"

  ih::setup::core.shell::private::configure-bashrc
  ih::setup::core.shell::private::configure-zshrc

  echo ""

  re_source

  export IH_WANT_RE_SOURCE=1
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

  if ih::setup::core.shell::private::validate-profile; then
    return 0
  fi

  local PROFILE_FILE="$IH_CUSTOM_DIR"/00_env.sh

  ih::ask::confirm "Your profile environment variables are not set up. Ready to input and update your variables?"
  local confirm_input=$?
  if [[ ${confirm_input} -ne 0 ]]; then
    echo "You can't continue bootstrapping until you've updated your environment variables."
    echo "You can manually edit ${PROFILE_FILE} and re-run the script."
    exit 1
  fi

  echo "Please enter the requested information for each prompt."

  local IH_HOME
  local GR_HOME
  local EMAIL_ADDRESS
  local GITHUB_USER
  local GITHUB_EMAIL_ADDRESS
  local FULL_NAME
  local IH_USERNAME
  local GR_USERNAME
  local JIRA_USERNAME
  local AWS_DEFAULT_ROLE

  read -p "Directory where you want to clone Legacy Grand Rounds repos [default: $HOME/src/github.com/ConsultingMD]: " IH_HOME
  GR_HOME="${IH_HOME:-$HOME/src/github.com/ConsultingMD}"

  read -p "Your Included Health email address: " EMAIL_ADDRESS
  read -p "Your GitHub username: " GITHUB_USER

  echo "The email address you want to associate with commits can be kept private following GitHub guidance."
  read -p "Commit email address [default: $EMAIL_ADDRESS]: " GITHUB_EMAIL_ADDRESS
  GITHUB_EMAIL_ADDRESS=${GITHUB_EMAIL_ADDRESS:-$EMAIL_ADDRESS}

  read -p "Your full name: " FULL_NAME
  read -p "Your username (probably firstname.lastname): " IH_USERNAME
  GR_USERNAME="$IH_USERNAME"

  echo "The username you have in JIRA has some specific rules."
  read -p "Your JIRA username: " JIRA_USERNAME

  read -p "The default value for AWS authentication [default: dev]: " AWS_DEFAULT_ROLE
  AWS_DEFAULT_ROLE=${AWS_DEFAULT_ROLE:-dev}

  # Now, let's write these to the file.
  cat > "$PROFILE_FILE" <<EOF
#!/bin/sh

# This file defines the user-specific environment variables ...

# Directory where you want to clone Legacy Grand Rounds repos,
# which are currently located in the ConsultingMD org.
export IH_HOME="$IH_HOME"
export GR_HOME="$GR_HOME"
export EMAIL_ADDRESS="$EMAIL_ADDRESS"
export GITHUB_USER="$GITHUB_USER"
export GITHUB_EMAIL_ADDRESS="$GITHUB_EMAIL_ADDRESS"
export FULL_NAME="$FULL_NAME"
export IH_USERNAME="$IH_USERNAME"
export GR_USERNAME="$GR_USERNAME"
export JIRA_USERNAME="$JIRA_USERNAME"
export AWS_DEFAULT_ROLE="$AWS_DEFAULT_ROLE"
EOF

  re_source

  if ih::setup::core.shell::private::validate-profile; then
    return 0
  else
    echo "Something went wrong with the profile validation. Please manually review the file: ${PROFILE_FILE}"
    exit 1
  fi
}

function set-editor() {
  read -r -p "Your EDITOR is unset. What editor do you like to use? (maybe enter vim or nano, or 'code -w' to use VSCode): " EDITOR
  export EDITOR
  echo "
  # This is the editor that will be used when a command-line tool
  # like git needs you to edit a file.
  export EDITOR=\"$EDITOR\"" >>"$PROFILE_FILE"
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
  VARS=$(grep export "$PROFILE_TEMPLATE_FILE" | grep -v "^#" | cut -f 2 -d" " - | cut -f 1 -d"=" -)

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
