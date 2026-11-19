#!/bin/bash
# shellcheck disable=SC1091

# This adds the asdf shims to the shell.
# For asdf v0.16.0+ (Go version) migration guide, see:
# https://asdf-vm.com/guide/upgrading-to-v0-16.html
#
# For detailed setup instructions:
# - Go-based asdf (v0.16.0+): https://asdf-vm.com/guide/getting-started.html
# - Bash-based asdf (pre-0.16.0): https://asdf-vm.com/guide/getting-started-legacy.html

function source_asdf() {
  local CURRENT_SHELL
  CURRENT_SHELL=$(ps -cp "$$" -o command="")
  local is_go_version=0

  # Check if asdf is installed and which version it is
  if command -v asdf >/dev/null 2>&1; then
    # Try to get the version
    local version
    version=$(asdf --version 2>/dev/null || echo "unknown")

    # Check if it's the Go version (0.16.0+)
    # Match versions like v0.16.x, 0.16.x, v1.x.x, 1.x.x
    if [[ "$version" =~ ^v?0\.1[6-9] ]] || [[ "$version" =~ ^v?[1-9] ]]; then
      is_go_version=1

      # Go version detected - use the official recommended setup
      if [ -z "$ASDF_DATA_DIR" ]; then
        export ASDF_DATA_DIR="$HOME/.asdf"
      fi

      # Add shims to PATH if not already there (this is the key part from the install guide)
      if [ -d "$ASDF_DATA_DIR/shims" ] && [[ ":$PATH:" != *":$ASDF_DATA_DIR/shims:"* ]]; then
        export PATH="$ASDF_DATA_DIR/shims:$PATH"
      fi

      # Set up ZSH completions for Go version
      if [[ $CURRENT_SHELL =~ "zsh" ]]; then
        # Create completions directory if it doesn't exist
        mkdir -p "${ASDF_DATA_DIR}/completions" 2>/dev/null

        # Generate completions if they don't exist
        if [ ! -f "${ASDF_DATA_DIR}/completions/_asdf" ]; then
          asdf completion zsh >"${ASDF_DATA_DIR}/completions/_asdf" 2>/dev/null
        fi

        # Add completions to fpath for zsh
        # shellcheck disable=SC2128,SC2206
        fpath=("${ASDF_DATA_DIR}/completions" $fpath)
        # Note: We don't run compinit here as it's handled by the zsh setup script
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

  # Add completions to fpath for zsh (for Bash-based asdf)
  # Only do this if we're not using the Go version (which already set up completions)
  if [[ $CURRENT_SHELL =~ "zsh" ]] && [ -n "$ASDF_DIR" ] && [ $is_go_version -eq 0 ]; then
    # shellcheck disable=SC2128,SC2206
    fpath=("${ASDF_DIR}/completions" $fpath)
    # Note: We don't run compinit here as it's handled by the zsh setup script
  fi
}

source_asdf
