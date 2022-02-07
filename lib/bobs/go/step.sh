#!/bin/bash

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.
BOBSGOVERSION="1.15.15"

function ih::setup::bobs.go::help() {
  echo "This correctly installs Go for use in the bobs repo

    This step will:
        - install an x86 version of go $BOBSGOVERSION for asdf
        - configure your shell with required go environment variables
    "
}

# Check if the step has been installed and return 0 if it has.
# Otherwise return 1.
function ih::setup::bobs.go::test() {

  if ! ih::file::check-shell-defaults "$IH_CORE_DIR"/lib/bobs/go/default; then
    return 1
  fi

  if ! asdf list golang | grep -q "$BOBSGOVERSION"; then
    return 1
  fi

  return 0
}

# Echo a space-delimited list of steps which must be installed before this one can be.
function ih::setup::bobs.go::deps() {
  # echo "step1 step2"
  echo ""
}

function ih::setup::bobs.go::install() {

  set -e

  ih::arch::x86 asdf install golang "$BOBSGOVERSION"

  ih::file::sync-shell-defaults "$IH_CORE_DIR"/lib/bobs/go/default

  export IH_WANT_RE_SOURCE=1
}
