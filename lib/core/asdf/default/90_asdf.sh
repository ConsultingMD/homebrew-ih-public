#!/bin/bash
# shellcheck disable=SC1091

# This adds the asdf shims to the shell.
# For asdf v0.16.0+ (Go version) migration guide, see:
# https://asdf-vm.com/guide/upgrading-to-v0-16.html

function source_asdf() {
  local CURRENT_SHELL
  CURRENT_SHELL=$(ps -cp "$$" -o command="")

  # Check if asdf is installed and which version it is
  if command -v asdf >/dev/null 2>&1; then
    # Try to get the version
    local version
    version=$(asdf --version 2>/dev/null || echo "unknown")

    # Check if it's the Go version (0.16.0+)
    # Match versions like v0.16.x, 0.16.x, v1.x.x, 1.x.x
    if [[ "$version" =~ ^v?0\.1[6-9] ]] || [[ "$version" =~ ^v?[1-9] ]]; then
      # Go version detected - use the official recommended setup
      if [ -z "$ASDF_DATA_DIR" ]; then
        export ASDF_DATA_DIR="$HOME/.asdf"
      fi

      # Add shims to PATH if not already there (this is the key part from the install guide)
      if [ -d "$ASDF_DATA_DIR/shims" ] && [[ ":$PATH:" != *":$ASDF_DATA_DIR/shims:"* ]]; then
        export PATH="$ASDF_DATA_DIR/shims:$PATH"
      fi

      return
    fi
  fi

  # Original asdf initialization for Bash-based versions (pre-0.16.0)
  if [ -f "$(brew --prefix asdf 2>/dev/null)/libexec/asdf.sh" ]; then
    . "$(brew --prefix asdf)/libexec/asdf.sh"
  elif [ -f "$HOME/.asdf/asdf.sh" ]; then
    . "$HOME/.asdf/asdf.sh"
    # Source bash completions
    if [[ $CURRENT_SHELL =~ "bash" ]]; then
      . "$HOME/.asdf/completions/asdf.bash"
    fi
  fi

  # Add completions to fpath for zsh
  # shellcheck disable=SC2206
  fpath=("${ASDF_DIR}/completions" $fpath)
}

source_asdf
