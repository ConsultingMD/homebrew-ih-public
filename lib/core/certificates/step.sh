#!/bin/bash

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.

function ih::setup::core.certificates::help() {
  # shellcheck disable=SC2016
  echo 'Trust the certificates used by the VPN DLP

    The GlobalProtect VPN uses self-signed certs to
    intercept and inspect SSL traffic. This is called the
    Data Loss Prevention or DLP system in various documents
    The CA used to sign the certs it uses is trusted by the OS,
    but some tools do not use the OS trust store. This step
    configures those tools to work correctly.

    This step will:
        - Place the CA files in $HOME/.ih/certs
        - Update the OpenSSL used by Homebrew
        - Tell node about the CA using NODE_EXTRA_CA_CERTS
        - Tell npm/yarn about CA certs
    '
}

# Check if the step has been installed and return 0 if it has.
# Otherwise return 1.
function ih::setup::core.certificates::test() {

  if [ ! -f "$IH_DEFAULT_DIR/11_certificates.sh" ]; then
    return 1
  fi

  if [ ! -d "$HOME/.ih/certs" ]; then
    return 1
  fi

  return 0
}

# Echo a space-delimited list of steps which must be installed before this one can be.
function ih::setup::core.certificates::deps() {
  echo "core.shell"
}

function ih::setup::core.certificates::install() {

  local CA_DIR="$HOME/.ih/certs"
  local CA_PATH="$CA_DIR/grand_rounds_chained_ca.pem"
  local MOZILLA_PATH="$CA_DIR"/mozilla.pem
  mkdir -p "$CA_DIR"
  ih::log::info "Copying internal CA certs into $CA_DIR"

  cp -f "$IH_CORE_LIB_DIR"/core/certificates/certs/* "$CA_DIR"

  ih::log::info "Acquiring cert bundle from Mozilla"
  curl https://curl.se/ca/cacert.pem >"$MOZILLA_PATH"
  # Append our DLP certs to the mozilla bundle.
  cat "$CA_PATH" >>"$MOZILLA_PATH"

  # Configure NPM to use the bundle.
  npm config set cafile "$HOME/.ih/certs/mozilla.pem"

  local OPENSSL_PATH OPENSSL_FOUND REHASH_PATH
  OPENSSL_PATH=$(brew info openssl | grep -oE "/usr/local/etc/openssl.*")
  OPENSSL_FOUND=$?
  if [[ "$OPENSSL_FOUND" -eq 0 ]]; then
    ih::log::info "Copying internal CA cert to brew OpenSSL certs..."
    cp "$CA_PATH" "$OPENSSL_PATH"/gr_root_ca.pem
    REHASH_PATH=$(brew info openssl | grep -oE "/usr/local/opt/openssl.*")
    $REHASH_PATH
  fi

  ih::log::info "Rehashing brew OpenSSL certs..."
  "$(brew --prefix)"/opt/openssl/bin/c_rehash

  ih::file::add-if-not-present "$HOME/.npmrc" "cafile=\"$MOZILLA_PATH\""
  ih::file::add-if-not-present "$HOME/.yarnrc" "cafile=\"$MOZILLA_PATH\""

  cp -f "$IH_CORE_LIB_DIR/core/certificates/default/11_certificates.sh" "$IH_DEFAULT_DIR/11_certificates.sh"

}
