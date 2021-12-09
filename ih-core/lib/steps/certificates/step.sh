#!/bin/bash

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.

function ih::setup::certificates::help() {
  echo 'Trust the certificates used by the VPN DLP

    The GlobalProtect VPN uses self-signed certs to
    intercept and inspect SSL traffic. The CA used to sign
    the certs it uses is trusted by the OS, but some tools
    do not use the OS trust store.

    This step will:
        - Update the OpenSSL used by Homebrew
        - Tell node about the CA using NODE_EXTRA_CA_CERTS
    '
}

# Check if the step has been installed and return 0 if it has.
# Otherwise return 1.
function ih::setup::certificates::test() {
  echo "Step installed"
  return 0
}

# Echo a space-delimited list of steps which must be installed before this one can be.
function ih::setup::certificates::deps() {
  # echo "step1 step2"
  echo ""
}

function ih::setup::certificates::install() {
  echo 'Installing...'
}
