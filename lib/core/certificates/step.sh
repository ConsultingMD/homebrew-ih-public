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

  # Our VPN performs an adversary-in-the-middle attack on
  # many domains so that it can scan traffic in an effort
  # to improve security. We need our engineering tools
  # (e.g. pip or npm) to trust the self-signed certificate
  # the VPN presents when it intercepts this traffic.
  # Unfortunately some versions of some tools don't trust
  # the system certificate store or the common OpenSSL store
  # and instead need to be given a path to CA file containing the
  # private root cert the VPN uses. Even more unfortunately,
  # some systems don't fall back to some other CA store when
  # the path you give them doesn't contain the cert they
  # are trying to verify, so if you're NOT on the VPN, or
  # you're hitting a domain which is excluded from the
  # inspection regime, validation fails because the
  # cert is NOT signed by our private CA. The solution is
  # to provide a CA file containing a collection of trusted
  # CA certs as well as our private CA cert, so that tools
  # will work in all scenarios. We download a certificate
  # bundle extracted from Firefox and documented at
  # https://curl.se/docs/caextract.html.
  local MOZILLA_BUNDLE_URL="https://curl.se/ca/cacert.pem"
  ih::log::info "Acquiring cert bundle from Mozilla"
  # Since we may be on the VPN and not trust the DLP certificate,
  # or our certificate bundle may be broken, we need to ignore
  # security problems when downloading the bundle. This is
  # obviously a security risk in its own right, but that's how
  # it goes with the VPN "security" system.
  curl --insecure "$MOZILLA_BUNDLE_URL" >"$MOZILLA_PATH"
  RESULT=$?
  if [ $RESULT -ne 0 ]; then
    ih::log::error "Could not download certificate bundle from $MOZILLA_BUNDLE_URL"
    return 1
  fi
  # Append our DLP certs to the mozilla bundle.
  cat "$CA_PATH" >>"$MOZILLA_PATH"

  # Download a CA cert that AWS sometimes uses, which is not
  # included in the Mozilla bundle. This affects a few people
  # with no obvious pattern.
  curl https://www.amazontrust.com/repository/SFSRootCAG2.pem >>"$MOZILLA_PATH"

  # Configure NPM to use the bundle, if npm exists.
  if command -v npm &>/dev/null; then
    npm config set cafile "$MOZILLA_PATH"
  fi

  if command -v yarn &>/dev/null; then
    # Configure yarn to use the bundle.
    yarn config set cafile "$MOZILLA_PATH"
  fi

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

  cp -f "$IH_CORE_LIB_DIR/core/certificates/default/11_certificates.sh" "$IH_DEFAULT_DIR/11_certificates.sh"
}
