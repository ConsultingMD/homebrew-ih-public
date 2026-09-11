#!/bin/bash

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.

function ih::setup::core.m1::help() {
  echo 'Installs M1 compatibility fixes if needed

    This step only runs if you have an M1
    CPU. It installs various things that make
    it easier to fall back to x86 mode for
    tools that do not work on M1. It will:
        - Install the x86 version of brew
        - Augment your shell setup with some aliases
            - x86 will start a new shell in x86 mode
            - amd64 will start a new shell in amd64 (M1) mode
        - Set up your shell so that if you are
          in x86 mode the x86 version of brew will be used.
    '
}

# Check if the step has been installed and return 0 if it has.
# Otherwise return 1.
function ih::setup::core.m1::test() {
  if sysctl -n machdep.cpu.brand_string | grep "M1"; then

    # M1 CPU detected
    if [ ! -x /usr/local/bin/brew ]; then
      ih::log::debug "Brew is not installed in x86 mode"
      return 1
    fi

    if ! ih::file::check-shell-defaults "${IH_CORE_LIB_DIR}/core/m1/default"; then
      ih::log::debug "M1 shell script out of date"
      return 1
    fi
  fi

  return 0
}

# Echo a space-delimited list of steps which must be installed before this one can be.
function ih::setup::core.m1::deps() {
  # echo "step1 step2"
  echo "core.shell"
}

function ih::setup::core.m1::install() {

  if [ ! -x /usr/local/bin/brew ]; then
    # Homebrew's installer now refuses to install under arch -x86_64 on
    # Apple Silicon, so clone Homebrew directly instead (must be a real
    # git clone, not a tarball, so `brew update` has a remote to fetch).
    ih::log::info "Installing x86 (Intel) Homebrew via manual clone"
    # Clear any partial clone from a prior interrupted run so this stays
    # retry-safe: `git clone` refuses a non-empty destination directory.
    sudo rm -rf /usr/local/Homebrew
    sudo mkdir -p /usr/local/Homebrew
    sudo chown -R "$(whoami)" /usr/local/Homebrew
    git clone https://github.com/Homebrew/brew.git /usr/local/Homebrew

    # brew needs to write formula/cask installs under these standard
    # prefix directories, which are root-owned by default on a stock Mac.
    # The official installer creates and chowns them; do the same here.
    local PREFIX_DIRS=(
      bin etc include lib opt sbin share
      var var/homebrew Cellar Caskroom Frameworks
    )
    for DIR in "${PREFIX_DIRS[@]}"; do
      sudo mkdir -p "/usr/local/$DIR"
    done
    sudo chown "$(whoami)" "${PREFIX_DIRS[@]/#//usr/local/}"

    sudo ln -sf /usr/local/Homebrew/bin/brew /usr/local/bin/brew
    /usr/local/bin/brew update --force >/dev/null
  fi

  ih::file::sync-shell-defaults "${IH_CORE_LIB_DIR}/core/m1/default"

  export IH_WANT_RE_SOURCE=1
}
