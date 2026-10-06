#!/bin/bash

# Shared helpers for the Claude Code setup steps and the agent updater.
# The standard content (AGENTS.md, settings defaults) lives in the private
# ConsultingMD/ih-agent-smith repo; these helpers read it from the clone that
# Claude Code keeps for the ih-coding-agents marketplace.

# These variables are used by the step files and the agent updater, which source this file.
# shellcheck disable=SC2034
IH_CLAUDE_DIR="${HOME}/.claude"
IH_CLAUDE_MARKETPLACE="ih-coding-agents"
IH_CLAUDE_MARKETPLACE_REPO="ConsultingMD/ih-agent-smith"
IH_CLAUDE_MARKETPLACE_DIR="${IH_CLAUDE_DIR}/plugins/marketplaces/${IH_CLAUDE_MARKETPLACE}"
IH_CLAUDE_PLUGIN="ih-dev-essentials@${IH_CLAUDE_MARKETPLACE}"

IH_CLAUDE_MANAGED_AGENTS_MD="${IH_CLAUDE_DIR}/ih/AGENTS.md"
# shellcheck disable=SC2088
IH_CLAUDE_AGENTS_MD_IMPORT='@~/.claude/ih/AGENTS.md'
IH_CLAUDE_USER_MD="${IH_CLAUDE_DIR}/CLAUDE.md"
IH_CLAUDE_SETTINGS="${IH_CLAUDE_DIR}/settings.json"

IH_AGENT_STATE_DIR="${HOME}/.ih/state"
# Records every settings default that was applied once, so it is never applied again.
IH_CLAUDE_SETTINGS_APPLIED="${IH_AGENT_STATE_DIR}/claude-settings-applied.json"
# Holds "<ok|failed> <epoch seconds>" for the last agent updater attempt.
IH_AGENT_UPDATER_STATUS="${IH_AGENT_STATE_DIR}/agent-updater.status"

# Puts the native installer's bin directory on the PATH if claude is not already there.
function ih::claude::ensure-path() {
  if ! command -v claude >/dev/null 2>&1 && [ -x "${HOME}/.local/bin/claude" ]; then
    export PATH="${HOME}/.local/bin:${PATH}"
  fi
}

# Returns 0 if the claude CLI is available.
function ih::claude::is-installed() {
  ih::claude::ensure-path
  command -v claude >/dev/null 2>&1
}

# Returns 0 if the claude CLI is signed in.
function ih::claude::is-signed-in() {
  claude auth status --json 2>/dev/null | jq -e '.loggedIn == true' >/dev/null
}

# Returns 0 if any Claude Code CLI session is running. The native install runs a binary
# named after its version, so match on argv[0] instead of the process name.
function ih::claude::is-running() {
  # shellcheck disable=SC2009
  ps -axo comm= | grep -qE '(^|/)claude$'
}

# Returns 0 if the ih-coding-agents marketplace is registered.
function ih::claude::marketplace-registered() {
  claude plugin marketplace list --json 2>/dev/null \
    | jq -e --arg name "$IH_CLAUDE_MARKETPLACE" 'any(.[]; .name == $name)' >/dev/null
}

# Echoes "enabled", "disabled", or "missing" for the ih-dev-essentials plugin at user scope.
function ih::claude::plugin-state() {
  local STATE
  STATE=$(claude plugin list --json 2>/dev/null \
    | jq -r --arg id "$IH_CLAUDE_PLUGIN" \
      'first(.[] | select(.id == $id and .scope == "user") | if .enabled then "enabled" else "disabled" end) // "missing"')
  echo "${STATE:-missing}"
}

# Refreshes the marketplace clone and updates every plugin installed from it.
# This is the recipe in ih-agent-smith docs/how-to/installing-plugins.md, which
# expects Claude Code to be closed while it runs.
function ih::claude::refresh-plugins() {
  if ! claude plugin marketplace update "$IH_CLAUDE_MARKETPLACE"; then
    ih::log::error "Could not refresh the $IH_CLAUDE_MARKETPLACE marketplace"
    return 1
  fi
  python3 "${IH_CLAUDE_MARKETPLACE_DIR}/scripts/refresh_plugins.py"
}

# Echoes the path of a standards file in the marketplace clone.
function ih::claude::standards-file() {
  echo "${IH_CLAUDE_MARKETPLACE_DIR}/standards/${1:?file name is required}"
}

# Returns 0 if the managed AGENTS.md copy matches the standard.
# A missing standard counts as in sync because there is nothing to copy yet.
function ih::claude::agents-md-in-sync() {
  local SRC
  SRC=$(ih::claude::standards-file AGENTS.md)
  [ ! -f "$SRC" ] || ih::file::check-file-in-sync "$SRC" "$IH_CLAUDE_MANAGED_AGENTS_MD"
}

# Copies the standard AGENTS.md over the managed copy. Never touches ~/.claude/CLAUDE.md.
function ih::claude::sync-agents-md() {
  local SRC
  SRC=$(ih::claude::standards-file AGENTS.md)
  if [ ! -f "$SRC" ]; then
    ih::log::debug "No standard AGENTS.md at $SRC; skipping"
    return 0
  fi
  mkdir -p "$(dirname "$IH_CLAUDE_MANAGED_AGENTS_MD")"
  cp -f "$SRC" "$IH_CLAUDE_MANAGED_AGENTS_MD"
}

# Returns 0 if ~/.claude/CLAUDE.md imports the managed AGENTS.md.
function ih::claude::agents-md-imported() {
  [ -f "$IH_CLAUDE_USER_MD" ] && grep -qxF "$IH_CLAUDE_AGENTS_MD_IMPORT" "$IH_CLAUDE_USER_MD"
}

# Applies the standard settings defaults to ~/.claude/settings.json without changing
# any value that is already there. Each leaf value and each array entry is applied at
# most one time, and is recorded in $IH_CLAUDE_SETTINGS_APPLIED, so a default that the
# engineer deletes stays deleted. If $1 is "test", changes nothing and returns 1 when
# there are defaults that were never applied.
function ih::claude::apply-settings-defaults() {
  local MODE="${1:-install}"
  local DEFAULTS
  DEFAULTS=$(ih::claude::standards-file claude-settings.json)
  if [ ! -f "$DEFAULTS" ]; then
    ih::log::debug "No standard settings defaults at $DEFAULTS; skipping"
    return 0
  fi

  local SETTINGS_JSON='{}' APPLIED_JSON='[]'
  [ -s "$IH_CLAUDE_SETTINGS" ] && SETTINGS_JSON=$(cat "$IH_CLAUDE_SETTINGS")
  [ -s "$IH_CLAUDE_SETTINGS_APPLIED" ] && APPLIED_JSON=$(cat "$IH_CLAUDE_SETTINGS_APPLIED")

  local RESULT
  RESULT=$(jq -n \
    --argjson settings "$SETTINGS_JSON" \
    --argjson applied "$APPLIED_JSON" \
    --slurpfile defaults "$DEFAULTS" '
    # Leaf paths in the defaults: values that are not objects, outside any array.
    def leaves: [paths(type != "object") as $p
                 | select($p | all(type == "string"))
                 | {path: $p, value: getpath($p)}];
    # One item per scalar leaf and one per array entry, each with a stable id.
    def items: [leaves[]
                | if (.value | type) == "array"
                  then .path as $p | .value[] | {id: (($p | tojson) + "[]" + tojson), path: $p, entry: .}
                  else {id: (.path | tojson), path: .path, value: .value}
                  end];
    ($defaults[0] | items | map(select(.id as $id | $applied | index([$id]) | not))) as $pending
    | reduce $pending[] as $item ({settings: $settings, applied: $applied, pending: ($pending | length)};
        (.settings | getpath($item.path)) as $current
        | if $item | has("entry") then
            if $current == null then .settings |= setpath($item.path; [$item.entry])
            elif ($current | type) == "array" and ($current | index([$item.entry]) | not)
            then .settings |= setpath($item.path; $current + [$item.entry])
            else . end
          elif $current == null then .settings |= setpath($item.path; $item.value)
          else . end
        | .applied += [$item.id])
    | .changed = (.settings != $settings)
  ') || {
    ih::log::error "Could not merge settings defaults into $IH_CLAUDE_SETTINGS"
    return 1
  }

  local PENDING
  PENDING=$(jq -r '.pending' <<<"$RESULT")
  if [ "$MODE" = "test" ]; then
    ih::log::debug "$PENDING settings defaults were never applied"
    [ "$PENDING" -eq 0 ]
    return
  fi
  if [ "$PENDING" -eq 0 ]; then
    return 0
  fi

  mkdir -p "$IH_CLAUDE_DIR" "$IH_AGENT_STATE_DIR"
  # Write through temp files so a failed write never leaves half a settings file.
  # Leave the settings file alone when every pending default was already set.
  if [ "$(jq -r '.changed' <<<"$RESULT")" = "true" ]; then
    # Write to the symlink target, so a settings file kept in a dotfiles repo stays linked.
    local SETTINGS_PATH
    SETTINGS_PATH=$(realpath "$IH_CLAUDE_SETTINGS" 2>/dev/null || echo "$IH_CLAUDE_SETTINGS")
    jq '.settings' <<<"$RESULT" >"${SETTINGS_PATH}.ih-tmp" \
      && mv -f "${SETTINGS_PATH}.ih-tmp" "$SETTINGS_PATH" \
      || return 1
  fi
  jq '.applied' <<<"$RESULT" >"${IH_CLAUDE_SETTINGS_APPLIED}.ih-tmp" \
    && mv -f "${IH_CLAUDE_SETTINGS_APPLIED}.ih-tmp" "$IH_CLAUDE_SETTINGS_APPLIED"
}
