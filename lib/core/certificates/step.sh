#!/bin/bash

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.

function ih::setup::core.certificates::help() {
  echo 'Trust the certificates used by the VPN DLP

    The GlobalProtect VPN uses self-signed certs to
    intercept and inspect SSL traffic. The CA used to sign
    the certs it uses is trusted by the OS, but some tools
    do not use the OS trust store.

    This step will:
        - Update the OpenSSL used by Homebrew
        - Tell node about the CA using NODE_EXTRA_CA_CERTS
        - Tell npm/yarn about CA certs
        - If Java is installed, update Java keystore for bazel
    '
}

# Check if the step has been installed and return 0 if it has.
# Otherwise return 1.
function ih::setup::core.certificates::test() {

  if [ ! -f "$IH_DEFAULT_DIR/11_certificates.sh" ]; then
    return 1
  fi

  if ! ih::setup::core.certificates::private::java-certs; then
    ih::log::debug "DLP certs not installed in Java keystore"
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
  local CA_PATH="$CA_DIR/ga_root_ca.pem"
  mkdir -p "$CA_DIR" >/dev/null

  ih::log::info "Copying internal CA cert into $CA_PATH"

  # Get the MITM'd cert chain from stackoverflow
  # and pull out the signing certificate chain and put it in a file.
  # We skip the first cert because it's the fake stackoverflow cert,
  # and we don't need it for anything.
  openssl s_client -showcerts -connect stackoverflow.com:443 </dev/null 2>/dev/null \
    | sed -n '/-----BEGIN CERTIFICATE-----/,/-----END CERTIFICATE-----/p' \
    | sed '1,/-----END CERTIFICATE-----/d' > \
      "$CA_PATH"

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

  ih::setup::core.certificates::private::java-certs "install"

  ih::file::add-if-not-present "$HOME/.npmrc" "cafile=\"$CA_PATH\""
  ih::file::add-if-not-present "$HOME/.yarnrc" "cafile=\"$CA_PATH\""

  cp -f "$IH_CORE_LIB_DIR/core/certificates/default/11_certificates.sh" "$IH_DEFAULT_DIR/11_certificates.sh"

}

# If $1 is set to "install" then this installs the certificates in the java cacerts store.
# Otherwise this returns 0 if the certificates are already installed, 1 if they are not.
function ih::setup::core.certificates::private::java-certs() {
  local JAVA_HOME JAVA_EXISTS JAVA_CERT_DIR
  JAVA_HOME=$(/usr/libexec/java_home)
  JAVA_EXISTS=$?
  if [[ $JAVA_EXISTS -eq 0 ]]; then
    for JAVA_CERT_DIR_CANDIDATE in "/lib/security/cacerts" "/jre/lib/security/cacerts"; do
      JAVA_CERT_DIR="${JAVA_HOME}${JAVA_CERT_DIR_CANDIDATE}"
      ih::log::debug "Looking for java install with certs at ${JAVA_CERT_DIR}..."

      if [ -f "$JAVA_CERT_DIR" ]; then
        ih::log::debug "Found java install with certs at $JAVA_CERT_DIR..."

        if keytool -list -v -storepass changeit -keystore "$JAVA_CERT_DIR" | grep -q "Grand Rounds"; then
          break
        else
          if [[ "$1" != "install" ]]; then
            # Not installing, just checking, so we should return 1
            # to indicate that the certs have not been installed.
            return 1
          fi
        fi

        local CERT_CHAIN ONE_CERT ONE_CERT_PATH
        local -i CERT_COUNT=1
        CERT_CHAIN=$(cat "$CA_PATH")
        ih::log::info "Cert chain: $CERT_CHAIN"
        until [[ -z $CERT_CHAIN ]]; do
          ih::log::info "Adding cert $CERT_COUNT to $JAVA_CERT_DIR..."
          ONE_CERT=$(echo "$CERT_CHAIN" | sed -n '1,/-----END CERTIFICATE-----/p')
          ONE_CERT_PATH=$(mktemp)

          ih::log::info "Placing cert in $ONE_CERT_PATH temporarily..."
          echo "$ONE_CERT" >"$ONE_CERT_PATH"

          ih::log::info "Adding cert to Java-usable keystore (needs sudo access)"
          sudo keytool -import -noprompt -storepass changeit -trustcacerts -alias "gr_cert_$CERT_COUNT" -file "$ONE_CERT_PATH" -keystore "$JAVA_CERT_DIR"
          CERT_CHAIN=$(echo "$CERT_CHAIN" | sed '1,/-----END CERTIFICATE-----/d')

          CERT_COUNT+=1
          # rm "$ONE_CERT_PATH"
        done

        local BAZEL_RC="startup --host_jvm_args=\"-Djavax.net.ssl.trustStore=$JAVA_CERT_DIR\" --host_jvm_args=-Djavax.net.ssl.keyStorePassword=changeit"

        if ! ih::file::add-if-not-matched "$HOME/.bazelrc" "startup" "$BAZEL_RC"; then
          ih::log::error "Could not add startup command to $HOME/.bazelrc, bazel may not work correctly until you update it"
          ih::log::error "Add this line to $HOME/.bazelrc (or update the existing startup to set the trustStore):"
          ih::log::error "$BAZEL_RC"
        fi
      fi
    done
  fi

}
