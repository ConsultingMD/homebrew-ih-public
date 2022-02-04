#!/bin/bash

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.

function ih::setup::bobs.bazel::help() {
  echo 'Installs bazel correctly

    This step will:
        - Install bazelisk in x86 mode
        - symlink bazel to bazelisk
        - Configure bazel keystore to trust DLP certificate
    '
}

# Check if the step has been installed and return 0 if it has.
# Otherwise return 1.
function ih::setup::bobs.bazel::test() {

  if ! type bazelisk >/dev/null 2>&1; then
    return 1
  fi

  if ! type bazel >/dev/null 2>&1; then
    return 1
  fi

  if ! ih::setup::bobs.bazel::private::java-certs; then
    ih::log::debug "DLP certs not installed in Java keystore"
    return 1
  fi

  return 0
}

# Echo a space-delimited list of steps which must be installed before this one can be.
function ih::setup::bobs.bazel::deps() {
  # echo "step1 step2"
  echo "core.certificates bobs.jdk"
}

function ih::setup::bobs.bazel::install() {

  set -e

  ih::arch::ibrew install bazelisk

  ln -s /usr/local/bin/bazelisk /usr/local/bin/bazel

  ih::setup::bobs.bazel::private::java-certs "install"
}

# If $1 is set to "install" then this installs the certificates in the java cacerts store.
# Otherwise this returns 0 if the certificates are already installed, 1 if they are not.
function ih::setup::bobs.bazel::private::java-certs() {
  local CA_DIR="$HOME/.ih/certs"
  local JAVA_HOME JAVA_EXISTS JAVA_CERT_DIR
  JAVA_HOME=$(/usr/libexec/java_home)
  JAVA_EXISTS=$?
  if [[ $JAVA_EXISTS -ne 0 ]]; then
    return 0
  fi

  for JAVA_CERT_DIR_CANDIDATE in "/lib/security/cacerts" "/jre/lib/security/cacerts"; do
    JAVA_CERT_DIR="${JAVA_HOME}${JAVA_CERT_DIR_CANDIDATE}"
    ih::log::debug "Looking for java install with certs at ${JAVA_CERT_DIR}..."

    if [ -f "$JAVA_CERT_DIR" ]; then
      ih::log::debug "Found java install with certs at $JAVA_CERT_DIR..."

      ih::log::debug "Installing certs in store"

      local -a CA_PATHS=(
        "$CA_DIR/grand_rounds_dlp_ca.pem"
        "$CA_DIR/grand_rounds_root_ca.pem"
      )

      for CA_PATH in "${CA_PATHS[@]}"; do
        local FINGERPRINT FINGERPRINT_OK
        FINGERPRINT=$(openssl x509 -in "$CA_PATH" -noout -fingerprint | cut -d"=" -f2)
        FINGERPRINT_OK=$?
        if [ ! $FINGERPRINT_OK ]; then
          return 1
        fi

        if keytool -list -v -storepass changeit -keystore "$JAVA_CERT_DIR" | grep -q "$FINGERPRINT"; then
          ih::log::debug "Cert store already contains GR CA cert from $CA_PATH"
          continue
        else
          if [[ "$1" != "install" ]]; then
            # Not installing, just checking, so we should return 1
            # to indicate that the certs have not been installed.
            ih::log::debug "Cert from path $CA_PATH not found in store"
            return 1
          fi
        fi

        ih::log::info "Adding cert $CA_PATH to $JAVA_CERT_DIR..."
        local CA_NAME
        CA_NAME=$(basename "$CA_PATH")

        ih::log::info "Adding cert to Java-usable keystore (needs sudo access)"
        sudo keytool -import -noprompt -storepass changeit -trustcacerts -alias "${CA_NAME%%.*}" -file "$CA_PATH" -keystore "$JAVA_CERT_DIR" || return 1
      done

      break
    fi
  done

  # JAVA_CERT_DIR will be set to the store where the cert was installed

  local BAZEL_RC="startup --host_jvm_args=\"-Djavax.net.ssl.trustStore=$JAVA_CERT_DIR\"
startup --host_jvm_args=-Djavax.net.ssl.keyStorePassword=changeit"
  if [[ "$1" == "install" ]]; then
    touch "$HOME/.bazelrc"
  fi
  if ! grep -q "$JAVA_CERT_DIR" "$HOME/.bazelrc"; then
    if [[ "$1" != "install" ]]; then
      return 1
    fi
    ih::log::info "Configuring bazel to use custom trust store..."
    if ! ih::file::add-if-not-matched "$HOME/.bazelrc" "startup" "$BAZEL_RC"; then
      ih::log::error "Could not add startup command to $HOME/.bazelrc, bazel may not work correctly until you update it"
      ih::log::error "Add these lines to $HOME/.bazelrc (or update the existing startup to set the trustStore):"
      ih::log::error "$BAZEL_RC"
    fi
  fi

}
