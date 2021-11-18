#!/bin/bash

function ecr-login() {

  set -e

  THIS_FILE=$(basename "$0")
  REGION=${AWS_DEFAULT_REGION:-"us-east-1"}
  OPS_ACCT=311088406905

  # Docker login is good for 12h. Refresh every 9h.
  MAX_LOGIN_MIN=$((60 * 9))
  SENTINEL_PATH=~/.aws/.ops_acct-ecr-login

  if ! command -v docker >/dev/null 2>&1; then
    exit
  fi

  if find "$SENTINEL_PATH" -mmin "-$MAX_LOGIN_MIN" 2>/dev/null | grep -q "$SENTINEL_PATH"; then
    echo "Already logged in to operations ECR repo. Force refresh with:"
    echo "  rm $SENTINEL_PATH; $THIS_FILE"
    exit
  fi

  if aws --version 2>&1 | grep -q 'aws-cli/1[.]'; then
    readonly cmd=$(aws ecr get-login --region "$REGION" --no-include-email --registry-ids "$OPS_ACCT")
    $cmd
  else
    aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$OPS_ACCT.dkr.ecr.$REGION.amazonaws.com"
  fi

  touch "$SENTINEL_PATH"
}
