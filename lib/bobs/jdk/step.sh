#!/bin/bash

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.

function ih::setup::bobs.jdk::help() {
  echo 'Installs the JDK version used by CDS

    This step will:
        - install open JDK 8
    '
}

# Check if the step has been installed and return 0 if it has.
# Otherwise return 1.
function ih::setup::bobs.jdk::test() {
  if ih::arch::ibrew list --cask adoptopenjdk8 >/dev/null 2>&1; then
    return 0
  fi
  return 1
}

# Echo a space-delimited list of steps which must be installed before this one can be.
function ih::setup::bobs.jdk::deps() {
  # echo "step1 step2"
  echo ""
}

function ih::setup::bobs.jdk::install() {

  ih::log::info "Tapping adoptopenjdk/openjdk"
  ih::arch::ibrew tap adoptopenjdk/openjdk

  ih::log::info "Installing adoptopenjdk8"
  ih::arch::ibrew install --cask adoptopenjdk8
}
