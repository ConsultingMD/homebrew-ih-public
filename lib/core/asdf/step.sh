#!/bin/bash

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.

ASDF_SH_TEMPLATE_PATH="$IH_CORE_LIB_DIR/core/asdf/default/90_asdf.sh"
ASDF_SH_PATH="$IH_DEFAULT_DIR/90_asdf.sh"
TOOL_VERSIONS_TEMPLATE_PATH="$IH_CORE_LIB_DIR/core/asdf/.tool-versions"
ASDF_VERSION="v0.14.1"

function ih::setup::core.asdf::help() {

  local CURRENT_VERSIONS
  CURRENT_VERSIONS=$(awk -v fmt="           %s %s\n" '{ printf fmt, $1, $2}' <"$TOOL_VERSIONS_TEMPLATE_PATH")
  echo "Install common asdf plugins and wire into shell

    This step will:
        - Install asdf by cloning into $HOME/.asdf (if it isn't installed)
        - Wire asdf shims into the shell
        - Install asdf plugins for commonly used apps
        - Install default versions for commonly used apps:
${CURRENT_VERSIONS}
    "
}

function detect_brew_asdf() {
  # Check if asdf is installed via Homebrew
  if brew list asdf &>/dev/null; then
    return 0 # asdf is installed via Homebrew
  fi

  return 1 # asdf is not installed via Homebrew
}

function uninstall_brew_asdf() {
  ih::log::info "Detected asdf installed via Homebrew."
  ih::log::info "This conflicts with ih-setup's asdf installation and can cause version conflicts."

  if ! ih::ask::confirm "Would you like to uninstall the Homebrew version of asdf?"; then
    ih::log::warn "Keeping Homebrew asdf installation. This may cause conflicts with ih-setup."
    return 1
  fi

  ih::log::info "Uninstalling asdf from Homebrew..."

  # Try standard uninstall first, then force if needed
  brew uninstall asdf 2>/dev/null || brew uninstall --force asdf 2>/dev/null

  # Check if uninstall was successful
  if brew list asdf &>/dev/null; then
    ih::log::error "Failed to uninstall asdf via brew. Please try manually with 'brew uninstall --force asdf'."
    return 1
  fi

  ih::log::info "Successfully uninstalled Homebrew asdf installation."

  return 0
}

function check_asdf_version() {
  local current_version

  if [ -d "$HOME/.asdf" ]; then
    cd "$HOME/.asdf" || return 1
    current_version=$(git describe --tags)

    if [ "$current_version" != "$ASDF_VERSION" ]; then
      ih::log::debug "Found asdf version $current_version, expecting $ASDF_VERSION"
      return 1
    fi
  fi
  return 0
}

# Check if the step has been installed and return 0 if it has.
# Otherwise return 1.
function ih::setup::core.asdf::test() {
  if ! command -v asdf >/dev/null; then
    ih::log::debug "asdf command is not available"
    return 1
  fi

  if detect_brew_asdf; then
    ih::log::debug "asdf is installed via Homebrew, which may conflict with ih-setup"
    return 1
  fi

  if [[ ! -f "$ASDF_SH_PATH" ]]; then
    ih::log::debug "asdf augment file not found at $ASDF_SH_PATH"
    return 1
  fi

  if ! ih::file::check-file-in-sync "$ASDF_SH_TEMPLATE_PATH" "$ASDF_SH_PATH"; then
    ih::log::debug "asdf augment file is out of sync with template"
    return 1
  fi

  if ! check_asdf_version; then
    ih::log::debug "asdf version check failed"
    return 1
  fi

  local CURRENT_PLUGINS
  CURRENT_PLUGINS=$(asdf plugin list)
  local DESIRED_PLUGINS
  DESIRED_PLUGINS=$(awk '{print $1}' "$TOOL_VERSIONS_TEMPLATE_PATH" | sort)

  local DIFF
  DIFF=$(diff <(echo "$CURRENT_PLUGINS") <(echo "$DESIRED_PLUGINS"))

  # check if desired had lines not present in current
  if [[ "$DIFF" =~ ">" ]]; then
    ih::log::debug "Some plugins are not installed"
    return 1
  fi

  return 0
}

function ih::setup::core.asdf::deps() {
  echo "core.shell core.git"
}

function recreate_shims() {
  ih::log::info "Removing existing asdf shims..."
  if [ -d "$HOME/.asdf/shims" ]; then
    rm -f "$HOME/.asdf/shims"/*
  else
    ih::log::debug "Shims directory not found."
    return 1
  fi

  ih::log::info "Generating new asdf shims..."
  asdf reshim

  local EXIT_CODE=$?
  if [ $EXIT_CODE -ne 0 ]; then
    ih::log::error "Failed to recreate asdf shims."
    return $EXIT_CODE
  fi

  ih::log::info "Successfully recreated asdf shims."
}

function clean_and_install_asdf() {
  if [ -d "$HOME/.asdf" ]; then
    if ! ih::ask::confirm "Found invalid asdf installation. This step will remove $HOME/.asdf and install asdf $ASDF_VERSION."; then
      ih::log::warn "Skipping asdf installation"
      return 1
    fi
    ih::log::info "Removing existing asdf installation... (this may prompt for a password)"
    sudo rm -rf "$HOME/.asdf"
  fi

  ih::log::info "Installing asdf $ASDF_VERSION..."
  git clone https://github.com/asdf-vm/asdf.git "$HOME"/.asdf --branch "$ASDF_VERSION"
  return 0
}

function ih::setup::core.asdf::install() {
  if detect_brew_asdf; then
    uninstall_brew_asdf
    # Even if user chooses not to uninstall, we continue with the rest of the setup
  fi

  # Fix asdf installation if needed
  if ! command -v asdf || ! check_asdf_version || [ ! -f "$HOME/.asdf/asdf.sh" ]; then
    # Try to update if it's a valid git repo
    if [ -d "$HOME/.asdf/.git" ]; then
      ih::log::info "Updating asdf to $ASDF_VERSION..."
      cd "$HOME/.asdf" || return 1
      git fetch --tags
      if ! git checkout "$ASDF_VERSION"; then
        clean_and_install_asdf || return 1
      fi
    else
      clean_and_install_asdf || return 1
    fi

    # If this is set it messes up asdf initialization
    unset ASDF_DIR
    # shellcheck disable=SC1091
    . "$HOME/.asdf/asdf.sh"
  fi

  local CURRENT_PLUGINS
  CURRENT_PLUGINS=$(asdf plugin list)

  local DESIRED_PLUGINS

  touch "$HOME/.tool-versions"

  # Shellcheck says useless cat but sort
  # shellcheck disable=SC2002
  DESIRED_PLUGINS=$(sort "$TOOL_VERSIONS_TEMPLATE_PATH")

  while IFS= read -r PLUGIN_VERSION; do
    local PLUGIN VERSION INSTALLED_VERSIONS
    PLUGIN=$(echo "$PLUGIN_VERSION" | awk '{print $1}')
    VERSION=$(echo "$PLUGIN_VERSION" | awk '{print $2}')
    ih::log::debug "Checking plugin for $PLUGIN"
    if [[ ! $CURRENT_PLUGINS =~ $PLUGIN ]]; then
      ih::log::info "Adding plugin for $PLUGIN"
      asdf plugin add "$PLUGIN"
    fi

    INSTALLED_VERSIONS=$(asdf list "$PLUGIN" 2>/dev/null)
    ih::log::debug "Checking if correct default version is installed for $PLUGIN_VERSION"
    if [[ ! $INSTALLED_VERSIONS =~ $VERSION ]]; then
      ih::log::info "Installing correct default version for $PLUGIN_VERSION"
      asdf install "$PLUGIN" "$VERSION"
      asdf global "$PLUGIN" "$VERSION"
    fi
  done <<<"$DESIRED_PLUGINS"

  recreate_shims

  ih::log::info "Copying augment file for shell"
  cp -f "$ASDF_SH_TEMPLATE_PATH" "$ASDF_SH_PATH"

  export IH_WANT_RE_SOURCE=1
}
