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

# Returns 0 if file $2 exists and is the same as file $1. Otherwise returns 1.
function ih::file::check-file-in-sync() {
  local SRC=${1:?"src is required"}
  local DST=${2:?"dst is required"}

  if [ ! -f "$DST" ]; then
    ih::log::debug "File $DST not found."
    return 1
  fi

  ih::log::debug "Checking for differences between $SRC and $DST ..."

  if ! diff -q "$DST" "$SRC" >/dev/null; then
    ih::log::debug "File $DST does not match source"
    return 1
  fi

  ih::log::debug "Files match"

}

# Returns 0 if the directory at $2 has all
# the files from the directory at $1, and
# the files are all the same. Otherwise returns 1.
function ih::file::check-dir-in-sync() {

  local SRC_DIR=${1:?"src is required"}
  local DST_DIR=${2:?"dst is required"}

  for SRC in "$SRC_DIR"/*; do
    local DST="${SRC/$SRC_DIR/$DST_DIR}"
    if ! ih::file::check-file-in-sync "$SRC" "$DST"; then
      return 1
    fi
  done
}

# Returns 0 if the shell default directory at ~/.ih/default
# contains exact matches for the files in the directory at $1.
# Otherwise returns 1.
function ih::file::check-shell-defaults() {

  local SRC_DIR=${1:?"src is required"}
  local DST_DIR="$IH_DIR"/default

  ih::file::check-dir-in-sync "$SRC_DIR" "$DST_DIR"
}

# Copies the files from $1 into the shell default directory at ~/.ih/default
# and makes them read/write
function ih::file::sync-shell-defaults() {

  local SRC_DIR=${1:?"src is required"}
  local DST_DIR="$IH_DIR"/default

  for SRC in "$SRC_DIR"/*; do
    ih::log::debug "Copying $SRC to $DST_DIR"
    cp -f "$SRC" "$DST_DIR"
    chmod 0600 "${DST_DIR}/$(basename "$SRC")"
  done
}

# Ensures the specified directory and its contents are owned by the current user
function ih::file::ensure_directory_ownership() {
  local dir_path="$1"

  if [[ -e "$dir_path" ]]; then
    local current_owner
    current_owner=$(stat -f '%Su' "$dir_path") # For macOS
    if [[ "$current_owner" != "$(whoami)" ]]; then
      ih::log::warn "Found $dir_path owned by '$current_owner' instead of current user"
      ih::log::info "Fixing ownership of $dir_path and its contents..."
      sudo chown -R "$(whoami)" "$dir_path"
      chmod -R 755 "$dir_path" 2>/dev/null || true
      ih::log::info "Fixed ownership of $dir_path"
    else
      ih::log::debug "$dir_path has correct ownership"
    fi
  fi
}
