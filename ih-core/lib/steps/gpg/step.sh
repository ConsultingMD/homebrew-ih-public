#!/bin/bash

# This automates creation and publishing of a GPG key
# Some of the logic was extracted from https://github.com/ConsultingMD/ops-tools/blob/32e62deea8a6ba4ba46fd19e0a57760632f32586/sysprep/linux/gr-genkey

#GPG Details:
# https://grandrounds.atlassian.net/wiki/spaces/SSL/pages/1258455581/How-To+Working+with+gpgKeychain+in+MacOS
# https://grandrounds.atlassian.net/wiki/spaces/EDS/pages/209453397/GPG+Keys

# Ask Rick Cobb, Jackie Keh and David from InfoSec about whether we need to have this GPG stuff

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.

function ih::setup::gpg::help() {
  echo 'Create and publish a GPG key

    This step will:
        - create a GPG key
        - publish the GPG key to a keyserver
    '
}

# Check if the step has been installed and return 0 if it has.
# Otherwise return 1.
function ih::setup::gpg::test() {

  # TODO: Check whether key is expired?

  gpg --list-keys "$EMAIL_ADDRESS" -eq 0 >/dev/null 2>/dev/null
  local RESULT=$?

  if [ $RESULT -ne 0 ]; then
    ih::log::debug "GPG key for $EMAIL_ADDRESS not found"
    return 1
  fi

  return 0
}

# Echo a space-delimited list of steps which must be installed before this one can be.
function ih::setup::gpg::deps() {
  echo "shell"
}

function ih::setup::gpg::disabled-install() {

  # TODO: Update key if it exists but is expired?

  local PASSWORD1
  local PASSWORD2
  echo "It's recommended that you generate a password in LastPass and paste it here."

  read -r -s -p "Enter a password for your GPG key:" PASSWORD1
  echo ""
  read -r -s -p "Confirm the password:" PASSWORD2
  echo ""

  if [[ "$PASSWORD1" != "$PASSWORD2" || -z $PASSWORD1 ]]; then
    if ih::private::retry-cancel "Passwords didn't match."; then
      ih::setup::gpg::install
      return
    else
      return 1
    fi
  fi

  local KEY_DEF
  KEY_DEF=$(mktemp)

  cat >"$KEY_DEF" <<EOF
Key-Type: RSA
Key-Length: 4096
Subkey-Type: RSA
Subkey-Length: 4096
Name-Real: $FULL_NAME
Name-Email: $EMAIL_ADDRESS
Passphrase: $PASSWORD1
Expire-Date: 2y
%commit
EOF

  gpg --batch --gen-key "$KEY_DEF"

  rm "$KEY_DEF"

  gpg --list-secret-keys

  # Getting the key ID is absurdly hard
  local KEY_ID
  KEY_ID=$(gpg --list-secret-keys --with-colons "$EMAIL_ADDRESS" | grep "fpr" | cut -d: -f 10)

  echo "Key ID: $KEY_ID"

  if ih::private::confirm "About to upload public key to key server"; then
    gpg --send-keys "$KEY_ID"
  fi
}
