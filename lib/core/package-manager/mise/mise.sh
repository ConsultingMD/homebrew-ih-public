#!/bin/bash

# mise support for the core.package-manager step. step.sh sources this file.

# Keep this version the same as MISE_VER in image-builder's docker/install-mise.sh, which pins
# the mise version that CI uses. image-builder's CI check fails when the two versions differ.
MISE_VERSION="v2026.11.5"

MISE_SH_TEMPLATE_PATH="$IH_CORE_LIB_DIR/core/package-manager/mise/90_mise.sh"
MISE_SH_PATH="$IH_DEFAULT_DIR/90_mise.sh"

# Echoes the tool and version pairs from .tool-versions, one per line.
function ih::pm::mise::tools() {
  awk 'NF >= 2 {print $1 "@" $2}' "$TOOL_VERSIONS_TEMPLATE_PATH"
}

# Echoes the installed mise version without the leading "v", for example "2026.10.21".
function ih::pm::mise::installed-version() {
  mise --version 2>/dev/null | awk 'NR == 1 {print $1}'
}

# Returns 0 if mise is installed at the pinned version, wired into the shell, and has the default tools.
function ih::pm::mise::test() {
  if ! command -v mise >/dev/null; then
    ih::log::debug "mise command is not available"
    return 1
  fi

  if [[ "$(ih::pm::mise::installed-version)" != "${MISE_VERSION#v}" ]]; then
    ih::log::debug "Found mise version $(ih::pm::mise::installed-version), expecting ${MISE_VERSION#v}"
    return 1
  fi

  if [[ ! -f "$MISE_SH_PATH" ]]; then
    ih::log::debug "mise augment file $MISE_SH_PATH is missing"
    return 1
  fi

  if ! ih::file::check-file-in-sync "$MISE_SH_TEMPLATE_PATH" "$MISE_SH_PATH"; then
    ih::log::debug "mise augment file is missing or out of sync with template"
    return 1
  fi

  local TOOL
  while IFS= read -r TOOL; do
    if ! mise where "$TOOL" >/dev/null 2>&1; then
      ih::log::debug "mise does not have $TOOL installed"
      return 1
    fi
  done < <(ih::pm::mise::tools)

  return 0
}

function ih::pm::mise::install() {
  if [[ "$(ih::pm::mise::installed-version)" != "${MISE_VERSION#v}" ]]; then
    ih::log::info "Installing mise ${MISE_VERSION} with the official installer"
    local INSTALLER
    INSTALLER=$(mktemp)
    if ! curl -fsSL -o "$INSTALLER" https://mise.jdx.dev/install.sh; then
      ih::log::error "Failed to download the mise installer"
      rm -f "$INSTALLER"
      return 1
    fi
    if ! MISE_VERSION="$MISE_VERSION" sh "$INSTALLER"; then
      ih::log::error "Failed to install mise ${MISE_VERSION}"
      rm -f "$INSTALLER"
      return 1
    fi
    rm -f "$INSTALLER"

    # The installer writes to $HOME/.local/bin, which the shell augment puts ahead of Homebrew.
    export PATH="$HOME/.local/bin:$PATH"

    if [[ "$(ih::pm::mise::installed-version)" != "${MISE_VERSION#v}" ]]; then
      ih::log::error "mise at $(command -v mise) is version $(ih::pm::mise::installed-version), expecting ${MISE_VERSION#v}"
      return 1
    fi
  fi

  local TOOL
  while IFS= read -r TOOL; do
    ih::log::info "Installing $TOOL and setting it as the global version"
    if ! mise use --global "$TOOL"; then
      ih::log::error "Failed to install $TOOL with mise"
      return 1
    fi
  done < <(ih::pm::mise::tools)

  ih::log::info "Copying augment file for shell"
  cp -f "$MISE_SH_TEMPLATE_PATH" "$MISE_SH_PATH"
  # Only one package manager can own the shell, so drop the asdf augment file.
  rm -f "$IH_DEFAULT_DIR/90_asdf.sh"

  export IH_WANT_RE_SOURCE=1
}
