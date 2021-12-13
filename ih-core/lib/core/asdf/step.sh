#!/bin/bash

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.

ASDF_SH_TEMPLATE_PATH="$IH_CORE_LIB_DIR/core/asdf/default/90_asdf.sh"
ASDF_SH_PATH="$IH_DEFAULT_DIR/90_asdf.sh"
TOOL_VERSIONS_TEMPLATE_PATH="$IH_CORE_LIB_DIR/core/asdf/.tool-versions"

function ih::setup::core.asdf::help() {
  echo "Install common asdf plugins and wire into shell

    This step will:
        - Install asdf by cloning into $HOME/.asdf (if it isn't installed)
        - Wire asdf shims into the shell
        - Install asdf plugins for commonly used apps
        - Install default versions for commonly used apps
    "
}

# Check if the step has been installed and return 0 if it has.
# Otherwise return 1.
function ih::setup::core.asdf::test() {

  if ! command -v asdf; then
    ih::log::debug "asdf command is not available"
    return 1
  fi

  if [[ ! -f "$ASDF_SH_PATH" ]]; then
    ih::log::debug "asdf augment file not found at $ASDF_SH_PATH"
    return 1
  fi

  local CURRENT_PLUGINS
  CURRENT_PLUGINS=$(asdf plugin list)
  local DESIRED_PLUGINS
  DESIRED_PLUGINS=$(awk '{print $1}' "$TOOL_VERSIONS_TEMPLATE_PATH" | sort)

  if [ "$CURRENT_PLUGINS" != "$DESIRED_PLUGINS" ]; then
    ih::log::debug "Some plugins are not installed"
    return 1
  fi

  return 0
}

# Echo a space-delimited list of steps which must be installed before this one can be.
function ih::setup::core.asdf::tags() {
  echo "core"
}

function ih::setup::core.asdf::deps() {
  echo "core.shell core.git"
}

function ih::setup::core.asdf::install() {

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

  ih::log::info "Copying augment file for shell"
  cp -f "$ASDF_SH_TEMPLATE_PATH" "$ASDF_SH_PATH"

  export IH_WANT_RE_SOURCE=1
}
