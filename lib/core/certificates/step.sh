#!/bin/bash

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.

CA_DIR="$HOME/.ih/certs"
SOURCE_CA_DIR="$IH_CORE_LIB_DIR/core/certificates/certs"
LEGACY_CERT_SCRIPT="$IH_DEFAULT_DIR/11_certificates.sh"
MOZILLA_PATH="$CA_DIR/mozilla.pem"
SYSTEM_BUNDLE="/etc/ssl/cert.pem"

function ih::setup::core.certificates::help() {
  # shellcheck disable=SC2016
  echo 'Place the internal CA certs in $HOME/.ih/certs

    The internal Grand Rounds CA certs are trusted by the OS
    through the System keychain. Some tools read them from
    $HOME/.ih/certs instead, such as docker-compose files that
    mount mozilla.pem.

    This step will:
        - Place the CA files in $HOME/.ih/certs
        - Point $HOME/.ih/certs/mozilla.pem at /etc/ssl/cert.pem
        - Remove the 11_certificates.sh shell script that older
          versions installed, which set SSL_CERT_FILE and other
          variables to a downloaded bundle
    '
}

# Check if the step has been installed and return 0 if it has.
# Otherwise return 1.
function ih::setup::core.certificates::test() {
  if [ -f "$LEGACY_CERT_SCRIPT" ]; then
    return 1
  fi

  local SOURCE_CA
  for SOURCE_CA in "$SOURCE_CA_DIR"/*.pem; do
    if ! diff -q "$SOURCE_CA" "$CA_DIR/$(basename "$SOURCE_CA")" >/dev/null 2>&1; then
      return 1
    fi
  done

  if [ ! -L "$MOZILLA_PATH" ] || [ "$(readlink "$MOZILLA_PATH")" != "$SYSTEM_BUNDLE" ]; then
    return 1
  fi

  return 0
}

# Echo a space-delimited list of steps which must be installed before this one can be.
function ih::setup::core.certificates::deps() {
  echo "core.shell"
}

function ih::setup::core.certificates::install() {
  mkdir -p "$CA_DIR"
  ih::log::info "Copying internal CA certs into $CA_DIR"
  cp -f "$SOURCE_CA_DIR"/*.pem "$CA_DIR"

  # Device management maintains /etc/ssl/cert.pem and re-links an
  # existing mozilla.pem to it, so a copy here would be replaced.
  if [ ! -L "$MOZILLA_PATH" ] || [ "$(readlink "$MOZILLA_PATH")" != "$SYSTEM_BUNDLE" ]; then
    ih::log::info "Linking $MOZILLA_PATH to $SYSTEM_BUNDLE"
    rm -f "$MOZILLA_PATH"
    ln -s "$SYSTEM_BUNDLE" "$MOZILLA_PATH"
  fi

  if [ -f "$LEGACY_CERT_SCRIPT" ]; then
    ih::log::info "Removing $LEGACY_CERT_SCRIPT. Open a new shell to clear SSL_CERT_FILE and the other variables it set."
    rm -f "$LEGACY_CERT_SCRIPT"
  fi
}
