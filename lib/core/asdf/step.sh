#!/bin/bash

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.

ASDF_SH_TEMPLATE_PATH="$IH_CORE_LIB_DIR/core/asdf/default/90_asdf.sh"
ASDF_SH_PATH="$IH_DEFAULT_DIR/90_asdf.sh"
TOOL_VERSIONS_TEMPLATE_PATH="$IH_CORE_LIB_DIR/core/asdf/.tool-versions"

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

# Check if the step has been installed and return 0 if it has.
# Otherwise return 1.
function ih::setup::core.asdf::test() {
  if ! command -v asdf >/dev/null; then
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

function ih::setup::core.asdf::install() {

  if ! command -v asdf; then
    ih::log::info "Cloning asdf into $HOME/.asdf"
    git clone https://github.com/asdf-vm/asdf.git "$HOME"/.asdf --branch v0.9.0
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

  ih::log::info "Copying augment file for shell"
  cp -f "$ASDF_SH_TEMPLATE_PATH" "$ASDF_SH_PATH"

  export IH_WANT_RE_SOURCE=1
}
