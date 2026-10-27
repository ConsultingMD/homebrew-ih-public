#!/bin/bash

# This activates mise in the shell. mise puts the tools from its configuration
# on the PATH, so it needs no shims.

function activate_mise() {
  command -v mise >/dev/null 2>&1 || return 0

  # asdf shims in the PATH take precedence over mise and give the wrong tool versions.
  local ASDF_SHIMS="${ASDF_DATA_DIR:-$HOME/.asdf}/shims"
  PATH=":${PATH}:"
  PATH="${PATH//:$ASDF_SHIMS:/:}"
  PATH="${PATH//:$HOME\/.asdf\/shims:/:}"
  PATH="${PATH#:}"
  export PATH="${PATH%:}"

  local CURRENT_SHELL
  CURRENT_SHELL=$(ps -cp "$$" -o command="")
  if [[ $CURRENT_SHELL =~ "zsh" ]]; then
    eval "$(mise activate zsh)"
  else
    eval "$(mise activate bash)"
  fi
}

activate_mise
