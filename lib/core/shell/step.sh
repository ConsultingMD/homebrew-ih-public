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

  if [[ -f ~/.bash_profile ]]; then
    if ! grep -q "source ~/.bashrc" ~/.bash_profile; then
      ih::log::debug ".bashrc not sourced from .bash_profile"
      return 1
    fi
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

  ih::setup::core.shell::private::configure-bash
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

function ih::setup::core.shell::private::configure-bash() {

  # If ~/.bashrc doesn't exist, create it
  if [[ ! -e ~/.bashrc ]]; then
    echo "Creating new ~/.bashrc"
    touch ~/.bashrc
  fi

  # Check if .bash_profile exists and if it doesn't already source .bashrc, then add it
  if [[ ! -e ~/.bash_profile || ! $(grep -q "source ~/.bashrc" ~/.bash_profile) ]]; then
    echo "Ensuring .bash_profile sources .bashrc..."
    echo "[[ -r ~/.bashrc ]] && source ~/.bashrc" >> ~/.bash_profile
  fi

  # shellcheck disable=SC2016
  if grep -qF -E '^[^#]+\.ih/augment.sh' ~/.bashrc; then
    echo "Included Health shell augmentation already sourced in ~/.bashrc"
  else
    echo "Appending Included Health config to ~/.bashrc"
    # shellcheck disable=SC2016
    echo "$BOOTSTRAP_SOURCE_LINE" >> ~/.bashrc

    echo "Updated ~/.bashrc to include this line at the end:

$BOOTSTRAP_SOURCE_LINE

If you want to source IH scripts earlier, adjust your ~/.bashrc"
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

function ih::setup::core.shell::private::collect-env-var() {
  local var_name="$1"
  local prompt_msg="$2"
  local default_val="$3"
  local input_val=""

  # If the variable is already set, skip
  if [[ -z ${!var_name} ]]; then
    while [[ -z $input_val && -z $default_val ]]; do
      read -p "$prompt_msg [$default_val]: " input_val
      # If the input is empty and there's no default, keep looping
      if [[ -z $input_val && -z $default_val ]]; then
        echo "This value cannot be left empty. Please provide a value."
      fi
    done
    # Use the default value if the input is empty
    export $var_name="${input_val:-$default_val}"
  fi
}

function ih::setup::core.shell::private::configure-profile() {
  echo "Please enter the requested information for each prompt."

  ih::setup::core.shell::private::collect-env-var "EDITOR" \
    "Your EDITOR is unset. What editor do you like to use? (maybe enter vim or nano, or 'code -w' to use VSCode)" \
    ""

  ih::setup::core.shell::private::collect-env-var "IH_HOME" \
    "Directory where you want to clone Legacy Grand Rounds repos" \
    "$HOME/src/github.com/ConsultingMD"
  export GR_HOME="$IH_HOME"
  ih::setup::core.shell::private::collect-env-var "EMAIL_ADDRESS" \
    "Your Included Health email address" \
    ""

  ih::setup::core.shell::private::collect-env-var "GITHUB_USER" \
    "Your GitHub username" \
    ""
  local default_email="$EMAIL_ADDRESS"
  ih::setup::core.shell::private::collect-env-var "GITHUB_EMAIL_ADDRESS" \
    "The email address you want to associate with commits. If you want to keep \
    your email address private, or have configured your email address to be \
    protected in GitHub, follow the guidance at \
    https://docs.github.com/en/account-and-profile/setting-up-and-managing-your-github-user-account/managing-email-preferences/setting-your-commit-email-address \
    and put the no-reply email address here. Otherwise, you can leave this as is." \
    "$default_email"

  ih::setup::core.shell::private::collect-env-var "FULL_NAME" \
    "Your full name, the name you would introduce yourself with" \
    ""
  ih::setup::core.shell::private::collect-env-var "IH_USERNAME" \
    "Your username, probably firstname.lastname" \
    ""
  export GR_USERNAME="$IH_USERNAME"
  local default_jira_username="$GR_USERNAME@includedhealth.com"
  ih::setup::core.shell::private::collect-env-var "JIRA_USERNAME" \
    "The username you have in JIRA. This is usually the email address you use to log in. \
    If you're uncertain, you can find it in your JIRA profile settings. When in JIRA, \
    click on your profile icon (usually in the top right corner), and it should be below your name. \
    If still in doubt, use: $default_jira_username as a default." \
    "$default_jira_username"

  ih::setup::core.shell::private::collect-env-var "AWS_DEFAULT_ROLE" \
    "This is the default value used to authenticate to AWS resources" \
    "dev"

  local PROFILE_FILE="$IH_CUSTOM_DIR"/00_env.sh

  # Ensure the file exists
  touch "$PROFILE_FILE"

  # Now, let's write these to the file.
  cat > "$PROFILE_FILE" <<EOF
#!/bin/sh

# This file defines the user-specific environment variables
# which are expected by other engineering scripts,
# as well as any additional things you want to add.

# This file will be sourced before any files in the default directory.

# This file will not be updated when you update the ih-core brew formula.

export EDITOR="$EDITOR"
# Directory where you want to clone Legacy Grand Rounds repos,
# which are currently located in the ConsultingMD org.
export IH_HOME="$IH_HOME"
export GR_HOME="$IH_HOME"
export EMAIL_ADDRESS="$EMAIL_ADDRESS"
export GITHUB_USER="$GITHUB_USER"
export GITHUB_EMAIL_ADDRESS="$GITHUB_EMAIL_ADDRESS"
export FULL_NAME="$FULL_NAME"
export IH_USERNAME="$IH_USERNAME"
export GR_USERNAME="$IH_USERNAME"
export JIRA_USERNAME="$JIRA_USERNAME"
export AWS_DEFAULT_ROLE="$AWS_DEFAULT_ROLE"
EOF

  # Set the file to be executable
  chmod +x "$PROFILE_FILE"

  echo "Environment variables have been written to '$PROFILE_FILE'."
  return 0
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
  local EXPECTED_VARS=(
    "IH_HOME"
    "EMAIL_ADDRESS"
    "GITHUB_USER"
    "GITHUB_EMAIL_ADDRESS"
    "FULL_NAME"
    "IH_USERNAME"
    "GR_USERNAME"
    "JIRA_USERNAME"
    "AWS_DEFAULT_ROLE"
  )

  for name in "${EXPECTED_VARS[@]}"; do
    value="${!name}"
    if [[ -z "$value" ]]; then
      return 1  # Return 1 as soon as an unset variable is found
    fi
  done

  return 0  # Return 0 if all variables are set
}
