#!/bin/bash

# Shared helpers for the Cursor setup steps and the agent updater.
# The standard content comes from the same ih-coding-agents marketplace clone that
# claude.sh reads. These helpers write Cursor's files even if Cursor is not installed,
# so a later Cursor install picks them up.

# These variables are used by the step files and the agent updater, which source this file.
# shellcheck disable=SC2034
IH_CURSOR_DIR="${HOME}/.cursor"
IH_CURSOR_CLI_CONFIG="${IH_CURSOR_DIR}/cli-config.json"
IH_CURSOR_SETTINGS_APPLIED="${HOME}/.ih/state/cursor-settings-applied.json"
# Cursor has no file for global rules, so the standard ships as a local plugin.
# Cursor does not load a local plugin through a symlink, so this is a real directory.
IH_CURSOR_PLUGIN_NAME="ih-standards"
IH_CURSOR_PLUGIN_DIR="${IH_CURSOR_DIR}/plugins/local/${IH_CURSOR_PLUGIN_NAME}"

# Applies the standard defaults to ~/.cursor/cli-config.json without changing any value
# that is already there. If $1 is "test", changes nothing and returns 1 when there are
# defaults that were never applied.
function ih::cursor::apply-cli-config-defaults() {
  # Cursor expects a version and both permission lists in a new file.
  ih::agent::apply-json-defaults "${1:-install}" \
    "$(ih::claude::standards-file cursor-cli-config.json)" \
    "$IH_CURSOR_CLI_CONFIG" "$IH_CURSOR_SETTINGS_APPLIED" \
    '{"version": 1, "permissions": {"allow": [], "deny": []}}' \
    expand-home
}

# Builds the ih-standards plugin in the empty directory $1.
function ih::cursor::build-plugin() {
  local OUT="${1:?output directory is required}"
  local AGENTS_MD SKILLS_LIST
  AGENTS_MD=$(ih::claude::standards-file AGENTS.md)
  SKILLS_LIST=$(ih::claude::standards-file cursor-skills.txt)

  mkdir -p "$OUT/.cursor-plugin" "$OUT/rules" || return 1
  cat >"$OUT/.cursor-plugin/plugin.json" <<EOF
{
  "name": "${IH_CURSOR_PLUGIN_NAME}",
  "description": "Engineering standards that ih-setup manages. Your edits are replaced on the next update."
}
EOF

  if [ -f "$AGENTS_MD" ]; then
    {
      printf -- '---\ndescription: Included Health engineering standards\nalwaysApply: true\n---\n\n'
      cat "$AGENTS_MD"
    } >"$OUT/rules/${IH_CURSOR_PLUGIN_NAME}.mdc" || return 1
  fi

  [ -f "$SKILLS_LIST" ] || return 0
  mkdir -p "$OUT/skills" || return 1
  local LINE SRC
  while IFS= read -r LINE || [ -n "$LINE" ]; do
    case "$LINE" in '' | '#'*) continue ;; esac
    SRC="${IH_CLAUDE_MARKETPLACE_DIR}/${LINE}"
    if [ ! -f "$SRC/SKILL.md" ]; then
      ih::log::warn "No skill at $SRC; skipping"
      continue
    fi
    # -L copies symlink targets, because Cursor skips symlinks.
    cp -RL "$SRC" "$OUT/skills/$(basename "$LINE")" || return 1
  done <"$SKILLS_LIST"
}

# Returns 0 if the installed ih-standards plugin matches what build-plugin makes.
# A missing standard counts as in sync because there is nothing to install yet.
function ih::cursor::plugin-in-sync() {
  [ -f "$(ih::claude::standards-file AGENTS.md)" ] || return 0
  local TEMP_DIR RESULT=0
  TEMP_DIR=$(mktemp -d /tmp/ih_cursor_plugin.XXXXXX)
  ih::cursor::build-plugin "$TEMP_DIR" >/dev/null 2>&1 \
    && diff -r "$TEMP_DIR" "$IH_CURSOR_PLUGIN_DIR" >/dev/null 2>&1 \
    || RESULT=1
  rm -rf "$TEMP_DIR"
  return $RESULT
}

# Replaces the installed ih-standards plugin with a fresh build.
function ih::cursor::sync-plugin() {
  if [ ! -f "$(ih::claude::standards-file AGENTS.md)" ]; then
    ih::log::debug "No standard AGENTS.md; skipping the Cursor plugin"
    return 0
  fi
  local PARENT TEMP_DIR
  PARENT=$(dirname "$IH_CURSOR_PLUGIN_DIR")
  mkdir -p "$PARENT" || return 1
  # Build next to the target, so the final move is a rename on one file system.
  TEMP_DIR=$(mktemp -d "${PARENT}/.${IH_CURSOR_PLUGIN_NAME}.XXXXXX") || return 1
  if ! ih::cursor::build-plugin "$TEMP_DIR"; then
    rm -rf "$TEMP_DIR"
    return 1
  fi
  rm -rf "$IH_CURSOR_PLUGIN_DIR"
  mv "$TEMP_DIR" "$IH_CURSOR_PLUGIN_DIR"
}
