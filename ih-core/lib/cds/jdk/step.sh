#!/bin/bash

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.

function ih::setup::cds.jdk::help() {
  echo 'Installs the JDK version used by CDS

    This step will:
        - install open JDK 8
    '
}

# Check if the step has been installed and return 0 if it has.
# Otherwise return 1.
function ih::setup::cds.jdk::test() {
  if brew list --cask adoptopenjdk8 >/dev/null; then
    return 0
  fi
  return 1
}

# Echo a space-delimited list of tags to apply to this step
# Tags are used to filter and group steps
function ih::setup::cds.jdk::tags() {
  echo "cds"
}

# Echo a space-delimited list of steps which must be installed before this one can be.
function ih::setup::cds.jdk::deps() {
  # echo "step1 step2"
  echo ""
}

function ih::setup::cds.jdk::install() {

  ih::log::info "Tapping adoptopenjdk/openjdk"
  brew tap adoptopenjdk/openjdk

  ih::log::info "Installing adoptopenjdk8"
  brew install --cask adoptopenjdk8
}
