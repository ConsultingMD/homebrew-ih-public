#!/bin/bash

# mise support for the core.package-manager step. step.sh sources this file.

MISE_SH_TEMPLATE_PATH="$IH_CORE_LIB_DIR/core/package-manager/mise/90_mise.sh"
MISE_SH_PATH="$IH_DEFAULT_DIR/90_mise.sh"

# Echoes the tool and version pairs from .tool-versions, one per line.
function ih::pm::mise::tools() {
  awk 'NF >= 2 {print $1 "@" $2}' "$TOOL_VERSIONS_TEMPLATE_PATH"
}

# Returns 0 if mise is installed, wired into the shell, and has the default tools.
function ih::pm::mise::test() {
  if ! command -v mise >/dev/null; then
    ih::log::debug "mise command is not available"
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
  if ! command -v mise >/dev/null; then
    ih::log::info "Installing mise with Homebrew"
    if ! brew install mise; then
      ih::log::error "Failed to install mise with brew"
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
