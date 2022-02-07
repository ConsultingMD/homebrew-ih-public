#!/bin/bash

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.

function ih::setup::bobs.scala::help() {
  echo 'This will install the correct scala

    This step will:
        - Install scala 2.12 in x86 mode
    '
}

# Check if the step has been installed and return 0 if it has.
# Otherwise return 1.
function ih::setup::bobs.scala::test() {
  if ! ih::arch::ibrew list scala@2.12 >/dev/null 2>&1; then
    return 1
  fi
  return 0
}

# Echo a space-delimited list of steps which must be installed before this one can be.
function ih::setup::bobs.scala::deps() {
  echo ""
}

function ih::setup::bobs.scala::install() {
  ih::arch::ibrew install scala@2.12
}
