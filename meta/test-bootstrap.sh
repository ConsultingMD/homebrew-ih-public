#!/bin/bash

THIS_DIR=$(dirname $(realpath "$0"))

export HOME=/tmp/ih-core-test
export ZDOTDIR=$HOME

command=${1:-""}


  case "${command}" in
  reset) 
    echo "Deleting temp home if it exists"
    test -d /tmp/ih-core-test && rm -rf /tmp/ih-core-test
    shift
    ;;
  esac

echo "Using $HOME as home"

mkdir -p /tmp/ih-core-test

BREW_BIN="$THIS_DIR/../ih-core/bin"

cd "$HOME"

export PATH="$BREW_BIN:$PATH"

unset GR_HOME
unset DOD_HOME
unset GITHUB_USER
unset EMAIL_ADDRESS
unset INITIALS
unset GR_USERNAME
unset JIRA_USERNAME
unset AWS_DEFAULT_ROLE

for name in $VARS; do
    unset $name
done

$BREW_BIN/ih-setup "$@"

if [[ ! $? ]]; then
    echo "Bootstrap failed"
    exit 1
fi

# If bootstrap succeeded, open a new shell in our test context.
zsh