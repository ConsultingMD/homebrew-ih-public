#!/bin/bash

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.

function ih::setup::core.agents-md::help() {
  echo 'Load the Included Health agent standards into every Claude Code session

    This step will:
    - Copy standards/AGENTS.md from ih-agent-smith to ~/.claude/ih/AGENTS.md,
      a file that ih-setup owns and replaces on each update
    - Add the line @~/.claude/ih/AGENTS.md to ~/.claude/CLAUDE.md.
      No other line in that file changes.'
}

function ih::setup::core.agents-md::test() {
  if ! ih::claude::agents-md-in-sync; then
    ih::log::debug "$IH_CLAUDE_MANAGED_AGENTS_MD does not match the standard"
    return 1
  fi

  if ! ih::claude::agents-md-imported; then
    ih::log::debug "$IH_CLAUDE_USER_MD does not import $IH_CLAUDE_MANAGED_AGENTS_MD"
    return 1
  fi
}

function ih::setup::core.agents-md::deps() {
  # The standard comes from the marketplace clone that this step sets up.
  echo "core.ih-dev-essentials"
}

function ih::setup::core.agents-md::install() {
  ih::claude::sync-agents-md || return 1

  if ! ih::claude::agents-md-imported; then
    ih::log::info "Adding $IH_CLAUDE_AGENTS_MD_IMPORT to $IH_CLAUDE_USER_MD"
    mkdir -p "$IH_CLAUDE_DIR"
    # Start a new line if the file does not end with one.
    if [ -s "$IH_CLAUDE_USER_MD" ] && [ -n "$(tail -c 1 "$IH_CLAUDE_USER_MD")" ]; then
      echo >>"$IH_CLAUDE_USER_MD"
    fi
    echo "$IH_CLAUDE_AGENTS_MD_IMPORT" >>"$IH_CLAUDE_USER_MD"
  fi
}
