#!/bin/bash

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.

function ih::setup::cds.bazel::help() {
  echo 'Installs bazelisk for bazel management

    This step will:
        - Install bazelisk
        - Check that bazel is working
    '
}

# Check if the step has been installed and return 0 if it has.
# Otherwise return 1.
function ih::setup::cds.bazel::test() {
  if type bazelisk >/dev/null; then
    if type bazel >/dev/null; then
      return 0
    fi
  fi
  return 1
}

# Echo a space-delimited list of steps which must be installed before this one can be.
function ih::setup::cds.bazel::deps() {
  # echo "step1 step2"
  echo ""
}

function ih::setup::cds.bazel::install() {

  set -e
  ih::log::info "Installing bazelisk using brew..."
  brew install bazelisk

  ih::log::info "Checking bazelisk version..."
  bazelisk version

  ih::log::info "Checking bazel version..."
  bazel version
}
