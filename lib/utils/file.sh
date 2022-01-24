#!/bin/bash

# These are file interaction functions that can be used by step scripts.

# Appends $2 to file $1 if the file doesn't already contain $2
# Also makes the directory containing the file if it doesn't exist,
# and creates the file if it doesn't exist.
function ih::file::add-if-not-present() {

  local FILE=$1
  local DIR
  local CONTENT=$2

  DIR=$(dirname "$FILE")

  mkdir -p "$DIR"

  touch "$FILE"

  if grep -q "$CONTENT" "$FILE"; then
    ih::log::debug "Content already present in $FILE, skipping"
    return 0
  fi

  ih::log::info "Adding content $FILE:"
  ih::log::info "$CONTENT"

  echo "$CONTENT" >>"$FILE"
}

# Appends $3 to file $1 if the file doesn't already contain
# a match for $2. This allows some flexibility about adding
# content to files. You should make sure that the content
# you are adding ($3) matches the match parameter ($2) or
# this command will not be idempotent.
# This returns 1 if the match hits but the file doesn't
# contain the exact content, so you can output additional messages.
# Also makes the directory containing the file if it doesn't exist,
# and creates the file if it doesn't exist.
function ih::file::add-if-not-matched() {

  local FILE=$1
  local MATCH=$2
  local DIR
  local CONTENT=$3

  DIR=$(dirname "$FILE")

  mkdir -p "$DIR"

  touch "$FILE"

  if grep -q "$MATCH" "$FILE"; then
    if grep -q "$CONTENT" "$FILE"; then
      ih::log::debug "Found sentinel $MATCH already present in $FILE (and exact content match), skipping"
      return 0
    else
      ih::log::debug "Found sentinel $MATCH already present in $FILE (but file did not contain content), skipping"
      return 1
    fi
  fi

  ih::log::info "Adding content $FILE:"
  ih::log::info "$CONTENT"

  echo "$CONTENT" >>"$FILE"
}

# Writes an array to file that can be sourced to populate a variable with the array.
# $1 is the name of the array
# $2 is the file name
function ih::file::write-array-to-file() {
  local NAME=$1
  local FILE=$2
  local ARR=("${!NAME}")
  chmod u+w "$FILE"
  echo "#!/usr/bin/env bash" >"$FILE"
  echo "export -a ${NAME}=(" >>"$FILE"
  for ITEM in "${ARR[@]}"; do
    echo "  \"${ITEM}\"" >>"$FILE"
  done
  echo ")" >>"$FILE"
}
