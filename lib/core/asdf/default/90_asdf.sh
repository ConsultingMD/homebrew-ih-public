#!/bin/bash
# shellcheck disable=SC1091

# This adds the asdf shims to the shell.

SHELL=$(ps -cp "$$" -o command="")

if [ -f "$(brew --prefix asdf 2>/dev/null)/libexec/asdf.sh" ]; then
  . "$(brew --prefix asdf)/libexec/asdf.sh"
elif [ -f "$HOME/.asdf/asdf.sh" ]; then
  . "$HOME/.asdf/asdf.sh"
  # Source bash completions
  if [[ $SHELL =~ "bash" ]]; then
    . "$HOME/.asdf/completions/asdf.bash"
  fi
fi

# Add completions to fpath for zsh
# shellcheck disable=SC2206
fpath=("${ASDF_DIR}/completions" $fpath)
