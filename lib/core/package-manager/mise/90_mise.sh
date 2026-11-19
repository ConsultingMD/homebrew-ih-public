#!/bin/bash

# This activates mise in the shell. mise puts the tools from its configuration
# on the PATH, so it needs no shims.

function activate_mise() {
  command -v mise >/dev/null 2>&1 || return 0

  # asdf shims in the PATH take precedence over mise and give the wrong tool versions.
  local ASDF_SHIMS="${ASDF_DATA_DIR:-$HOME/.asdf}/shims"
  local NEW_PATH=":${PATH}:"
  while [[ "$NEW_PATH" == *":$ASDF_SHIMS:"* ]]; do
    NEW_PATH="${NEW_PATH//:$ASDF_SHIMS:/:}"
  done
  NEW_PATH="${NEW_PATH#:}"
  export PATH="${NEW_PATH%:}"

  if [[ -n "${ZSH_VERSION:-}" ]]; then
    eval "$(mise activate zsh)"
  else
    eval "$(mise activate bash)"
  fi
}

activate_mise
