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
  local is_go_version=0
  local version binary

  if ! command -v asdf >/dev/null 2>&1; then
    return 0
  fi

  binary=$(command -v asdf)
  version=$(command asdf --version 2>/dev/null || echo "unknown")
  # Normalize: "asdf version 0.19.0" or "v0.14.1-f00f759"
  if [[ "$version" == *version* ]]; then
    version=${version##*version }
  fi
  version=${version%% *}

  # Go asdf: 0.16+, 0.19+, 1.x+
  if [[ "$version" =~ ^v?0\.(1[6-9]|[2-9][0-9]+) ]] || [[ "$version" =~ ^v?[1-9][0-9]*(\.[0-9]+)*$ ]]; then
    is_go_version=1
  fi
  # brew Go asdf has no libexec/asdf.sh; prefer non-legacy binary
  if [[ $is_go_version -eq 0 ]] && [[ -x "$binary" ]] \
    && [[ ! -f "$(brew --prefix asdf 2>/dev/null)/libexec/asdf.sh" ]] \
    && [[ "$binary" != *"/.asdf/bin/asdf" ]]; then
    is_go_version=1
  fi

  # Go version detected - use the official recommended setup
  if [[ $is_go_version -eq 1 ]]; then
    if [ -z "$ASDF_DATA_DIR" ]; then
      export ASDF_DATA_DIR="$HOME/.asdf"
    fi

    if type brew &>/dev/null; then
      local _asdf_brew_prefix
      _asdf_brew_prefix="$(brew --prefix asdf 2>/dev/null)"
      if [[ -n $_asdf_brew_prefix && -x "${_asdf_brew_prefix}/bin/asdf" ]]; then
        export PATH="${_asdf_brew_prefix}/bin:$PATH"
      fi
    fi

    # Add shims to PATH if they're not already in the path
    if [ -d "$ASDF_DATA_DIR/shims" ] && [[ ":$PATH:" != *":$ASDF_DATA_DIR/shims:"* ]]; then
      export PATH="$ASDF_DATA_DIR/shims:$PATH"
    fi

    # zsh: add completions to fpath
    if [[ -n "${ZSH_VERSION:-}" ]]; then
      mkdir -p "${ASDF_DATA_DIR}/completions" 2>/dev/null
      if [ ! -f "${ASDF_DATA_DIR}/completions/_asdf" ]; then
        command asdf completion zsh >"${ASDF_DATA_DIR}/completions/_asdf" 2>/dev/null
      fi
      # shellcheck disable=SC2128,SC2206
      fpath=("${ASDF_DATA_DIR}/completions" $fpath)
    fi

    return
  fi

  # Original asdf initialization for Bash-based versions (pre-0.16.0)
  echo "asdf ${version:-unknown} is legacy; upgrade: https://asdf-vm.com/guide/upgrading-to-v0-16.html" >&2

  if [ -f "$(brew --prefix asdf 2>/dev/null)/libexec/asdf.sh" ]; then
    # shellcheck disable=SC1091
    . "$(brew --prefix asdf)/libexec/asdf.sh"
  elif [ -f "$HOME/.asdf/asdf.sh" ]; then
    # shellcheck disable=SC1091
    . "$HOME/.asdf/asdf.sh"
    if [[ -n "${BASH_VERSION:-}" ]]; then
      # shellcheck disable=SC1091
      . "$HOME/.asdf/completions/asdf.bash"
    fi
  fi

  if [[ -n "${ZSH_VERSION:-}" ]] && [ -n "$ASDF_DIR" ]; then
    # shellcheck disable=SC2128,SC2206
    fpath=("${ASDF_DIR}/completions" $fpath)
  fi
}

# Zsh: define only; 99_zsh.zsh adds shims at startup. Bash: eager init.
if [[ -n "${BASH_VERSION:-}" ]]; then
  source_asdf
fi
