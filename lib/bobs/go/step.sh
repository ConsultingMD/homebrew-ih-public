#!/bin/bash

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.
BOBSGOVERSION="1.15.15"

function ih::setup::bobs.go::help() {
  echo "This correctly installs Go for use in the bobs repo

    This step will:
        - install an x86 version of go $BOBSGOVERSION with asdf or mise
        - configure your shell with required go environment variables
    "
}

# Echoes the package manager that core.package-manager chose: mise or asdf.
function ih::setup::bobs.go::pm() {
  if declare -F ih::pm::choice >/dev/null; then
    ih::pm::choice
  elif command -v asdf >/dev/null; then
    echo asdf
  else
    echo mise
  fi
}

# Check if the step has been installed and return 0 if it has.
# Otherwise return 1.
function ih::setup::bobs.go::test() {

  if ! ih::file::check-shell-defaults "$IH_CORE_DIR"/lib/bobs/go/default; then
    return 1
  fi

  if [[ "$(ih::setup::bobs.go::pm)" == "asdf" ]]; then
    asdf list golang | grep -q "$BOBSGOVERSION" || return 1
  else
    mise where "golang@$BOBSGOVERSION" >/dev/null 2>&1 || return 1
  fi

  return 0
}

# Echo a space-delimited list of steps which must be installed before this one can be.
function ih::setup::bobs.go::deps() {
  # echo "step1 step2"
  echo "core.package-manager"
}

function ih::setup::bobs.go::install() {

  set -e

  if [[ "$(ih::setup::bobs.go::pm)" == "asdf" ]]; then
    ih::arch::x86 asdf install golang "$BOBSGOVERSION"
  else
    ih::arch::x86 mise install "golang@$BOBSGOVERSION"
  fi

  ih::file::sync-shell-defaults "$IH_CORE_DIR"/lib/bobs/go/default

  export IH_WANT_RE_SOURCE=1
}
