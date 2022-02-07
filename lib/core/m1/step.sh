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
    arch -x86_64 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
  fi

  ih::file::sync-shell-defaults "${IH_CORE_LIB_DIR}/core/m1/default"

  export IH_WANT_RE_SOURCE=1
}
