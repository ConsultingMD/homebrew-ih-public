#!/bin/bash

set -e

THIS_FILE=$(basename "$0")

CONFIG_FILE=~/.aws/config
ACCESS_DB=~/.aws/access.db
SSO_ACCT_ID=311088406905
SSO_BOOTSTRAP_ROLE=Basic_User
# AWS SSO is single region
SSO_REGION=us-east-1
SSO_START_URL="https://grandrounds.awsapps.com/start"
USER_REGIONS=(us-east-1 us-west-2)

# Cache for `aws sso get-role-credentials`
ROLE_CREDS_CACHE=~/.aws/role-creds
# Get new creds if cached creds are close to expiration
MIN_REMAINING_SEC=7200

# Versions prior to this are incompatible with the
# gr cli because of a change in timestamp format
# https://github.com/aws/aws-cli/pull/5826/files
MIN_AWS_VERSION=(2 1 14)

clean-env() {
  # Do not enherit AWS settings
  unset AWS_ACCESS_KEY_ID
  unset AWS_DEFAULT_ROLE
  unset AWS_PROFILE
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_SESSION_TOKEN
}

pad_version() {
  major=${1:?}
  minor=${2:?}
  patch=${3:?}
  printf "%05d%05d%05d" "$major" "$minor" "$patch"
}

check-version() {
  aws_cmd="${1:?}"

  read -r major minor patch _ <<<"$("$aws_cmd" --version 2>&1 | tr -c '[:digit:]' ' ')"

  padded_min=$(pad_version "${MIN_AWS_VERSION[@]}")
  padded_cur=$(pad_version "$major" "$minor" "$patch")

  [ "$padded_cur" -ge "$padded_min" ]
}

ensure-aws-v2() {
  [ "$AWS_V2" ] && return

  local cmd

  # Get v2 aws cli from anywhere in PATH. This prevents package
  # managers like pip from hiding the correct aws install
  for cmd in $(type -fa aws | awk '{print $NF}'); do
    if check-version "$cmd"; then
      AWS_V2="$cmd"
      break
    fi
  done

  if [ ! "$AWS_V2" ]; then
    (
      echo "Error: AWS CLI is too old. Install latest version of the v2 CLI."
      echo "See https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html"
      echo
      echo "On mac you can install with the following:"
      echo "  curl https://awscli.amazonaws.com/AWSCLIV2.pkg -o /tmp/AWSCLIV2.pkg"
      echo "  sudo installer -pkg /tmp/AWSCLIV2.pkg -target /"
      echo "  rm /tmp/AWSCLIV2.pkg"
    ) >/dev/stderr
    exit 1
  fi
}

aws-wrapper() {
  ensure-aws-v2

  "${AWS_V2:?}" --region "$SSO_REGION" "$@"
}

use-bootstrap-config() {
  AWS_CONFIG_FILE=$(mktemp)
  export AWS_CONFIG_FILE

  bootstrap-config >"$AWS_CONFIG_FILE"
}

bootstrap-config() {
  # Make the SSO bootstrap config the default profile
  #
  # This profile is available to all AWS SSO users and grants minimal
  # permissions needed to discover accounts and roles available to the
  # current user.
  cat <<HERE
[profile default]
sso_start_url = ${SSO_START_URL:?}
sso_region = ${SSO_REGION:?}
sso_account_id = ${SSO_ACCT_ID:?}
sso_role_name = ${SSO_BOOTSTRAP_ROLE:?}
region = ${AWS_DEFAULT_REGION:us-east-1}

HERE
}

login() {
  # Try to used cached creds
  TOKEN=$(access-token)
  if [ "$TOKEN" ]; then
    return
  fi

  # Warn if GlobalProtect VPN appears not to be enabled
  # Test server 10.12.133.43 maintained by IT should be reachable on GlobalProtect
  if ! curl --max-time 5 --fail --silent http://10.12.133.43 -o /dev/null; then
    echo "Failed to reach VPN connection check server" >/dev/stderr
    echo "WARNING: GlobalProtect VPN is required!" >/dev/stderr
    echo "Attempting login via Okta anyway" >/dev/stderr
  else
    echo "Logging in via Okta" >/dev/stderr
  fi

  # Login and get fresh creds
  aws-wrapper sso login >/dev/stderr
  TOKEN=$(access-token)
  if ! [ "$TOKEN" ]; then
    echo "Failed to set sso access token" >/dev/stderr
    exit 1
  fi
}

access-token() {
  local token utc_now

  utc_now=$(TZ=UTC0 date +%Y-%m-%dT%H:%M:%S)

  token="$(
    cat ~/.aws/sso/cache/*.json |
      jq -r '. |
             select(.startUrl == "https://grandrounds.awsapps.com/start") |
             select(.region == "'${SSO_REGION:?}'") |
             select(.expiresAt > "'"$utc_now"'") |
             .accessToken' |
      head -1
  )"

  if ! [ "$token" ]; then
    return
  fi

  if ! validate-token "$token"; then
    # Removes invalid token from aws sso cache
    aws-wrapper sso logout
    return
  fi

  echo "$token"
}

validate-token() {
  aws-wrapper sso list-accounts --max-items=1 --access-token "${1:?}" >/dev/null 2>&1
}

generate-access-db() {
  # Populates access db file with entries:
  #  <Account Name> <Account Id> <SSO Role>
  echo "Discovering available accounts and roles" >/dev/stderr
  out=$(mktemp)
  get-accounts | while read -r acct_id acct_name; do
    get-roles "$acct_id" | while read -r role; do
      echo "$acct_id $acct_name $role" >>"$out"
    done
  done

  sort --ignore-case -k 2 "$out" >"$ACCESS_DB"
  rm "$out"
}

generate-profiles() {
  bootstrap-config

  # Genereate profile blocks for each account/role
  while read -r acct_id acct_name role; do
    for region in "${USER_REGIONS[@]}"; do
      config-block "$acct_name" "$acct_id" "$region" "$role"
    done
  done <"$ACCESS_DB"
}

get-accounts() {
  aws-wrapper sso list-accounts --access-token "${TOKEN:?}" | jq -r '.accountList[] | "\(.accountId) \(.accountName)"'
}

get-roles() {
  acct_id=${1:?}
  aws-wrapper sso list-account-roles --access-token "${TOKEN:?}" --account-id "$acct_id" |
    jq -r '.roleList[] | .roleName'
}

config-block() {
  acct_name=${1:?}
  acct_id=${2:?}
  region=${3:?}
  sso_role=${4:?}

  # normalize to lowercase for consistency
  profile_name=$(echo "$acct_name-$sso_role-$region" | tr '[:upper:]' '[:lower:]')

  cat <<HERE
[profile $profile_name]
sso_start_url = $SSO_START_URL
sso_region = $SSO_REGION
sso_account_id = $acct_id
sso_role_name = $sso_role
region = $region

HERE
}

generate() {
  # Generates ~/.aws/config and access.db used by show()
  use-bootstrap-config
  refresh
  generate-access-db
  cfg=$(mktemp)
  generate-profiles >"$cfg"

  if [ -f "$CONFIG_FILE" ]; then
    save="$CONFIG_FILE.save.$(date +%s)"
    mv "$CONFIG_FILE" "$save"
    mv "$cfg" "$CONFIG_FILE"

    if diff "$CONFIG_FILE" "$save" >/dev/null; then
      rm "$save"
      echo "No changes to $CONFIG_FILE" >/dev/stderr
    else
      echo "Updated $CONFIG_FILE. Previous config saved at $save." >/dev/stderr
    fi
  else
    mv "$cfg" "$CONFIG_FILE"
    echo "Created $CONFIG_FILE" >/dev/stderr
  fi
}

# shellcheck disable=SC2059
show() {
  # Prints list of accounts/roles that can assumed by user.
  # Accounts and roles are normalized to lowercase.
  if ! [ -f $ACCESS_DB ]; then
    generate
    echo >/dev/stderr
  fi

  fmt="%-20s %s\n"

  printf "$fmt" Account Role

  cut -d " " -f 2,3 "$ACCESS_DB" |
    tr "[:upper:]" "[:lower:]" |
    while read -r acct role; do
      printf "$fmt" "$acct" "$role"
    done
}

refresh() {
  # Refresh SSO login and discard cached credentials
  rm -rf "$ROLE_CREDS_CACHE"
  aws-wrapper sso logout >/dev/stderr
  login
}

check() {
  # Checks that configuration is present and not empty
  # Status of 2 indicates generate is needed
  if [ ! -s "$ACCESS_DB" ]; then
    return 2
  fi

  if ! grep -q "profile default" "$CONFIG_FILE"; then
    return 2
  fi

  if ! grep -q "profile operations-basic_user-us-east-1" "$CONFIG_FILE"; then
    return 2
  fi
}

get-role-credentials() {
  local acct_id="${1:?}"
  local role="${2:?}"

  mkdir -p $ROLE_CREDS_CACHE
  creds_file="$ROLE_CREDS_CACHE/$role-$acct_id"

  if test -f "$creds_file"; then
    expiration=$(jq -r .roleCredentials.expiration <"$creds_file")
    if [ "$expiration" ]; then
      now=$(date +%s)
      remaining_sec=$((expiration / 1000 - now))
      if [ $remaining_sec -gt $MIN_REMAINING_SEC ]; then
        cat "$creds_file"
        return
      fi
    fi
  fi

  login
  aws-wrapper sso get-role-credentials --access-token "${TOKEN:?}" --role-name "$role" --account-id "$acct_id" >"$creds_file"
  cat "$creds_file"
}

credentials() {
  # Dump temporary credentials for current profile
  (
    # Restore original environment
    msg="Run aws-environment first"
    : "${AWS_ENVIRONMENT:?$msg}"
    : "${AWS_ENVIRONMENT_ROLE:?$msg}"

    acct_id=$(awk 'tolower($2) == ENVIRON["AWS_ENVIRONMENT"] {print $1; exit}' <$ACCESS_DB)
    role=$(awk 'tolower($3) == ENVIRON["AWS_ENVIRONMENT_ROLE"] {print $3; exit}' <$ACCESS_DB)

    out=$(mktemp)
    get-role-credentials "$acct_id" "$role" >"$out"

    key_id=$(jq -r .roleCredentials.accessKeyId <"$out")
    secret_key=$(jq -r .roleCredentials.secretAccessKey <"$out")
    session_token=$(jq -r .roleCredentials.sessionToken <"$out")
    rm "$out"

    cat <<HERE
unset AWS_PROFILE
export AWS_ACCESS_KEY_ID=$key_id
export AWS_SECRET_ACCESS_KEY=$secret_key
export AWS_SESSION_TOKEN=$session_token
export AWS_ENVIRONMENT=${AWS_ENVIRONMENT:?}
HERE
  )
}

function aws-sso-setup() {

  cmd="${1}"

  valid_commands=(generate show login refresh check credentials)
  for valid in "${valid_commands[@]}"; do
    if [ "$cmd" = "$valid" ]; then
      found=1
      break
    fi
  done

  if [ ! "$found" ]; then
    echo "$THIS_FILE: Valid commands are: " "${valid_commands[@]}" >/dev/stderr
    exit 1
  fi

  clean-env

  "$cmd"
}
