#!/bin/zsh

# This script tests the ih-setup script be creating 
# a temporary home directory and setting $HOME to it,
# then starting a new shell in that directory.
# It also adds the bin directory of ih-core to the 
# path to simulate having installed it using brew.


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

BIN_DIR="$THIS_DIR/../ih-core/bin"

cd "$HOME"

export PATH="$BIN_DIR:$PATH"

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

export BIN_DIR=$BIN_DIR

$BIN_DIR/ih-setup

if [[ ! $? ]]; then
    echo "Bootstrap failed"
    exit 1
fi

# If bootstrap succeeded, open a new shell in our test context.
zsh