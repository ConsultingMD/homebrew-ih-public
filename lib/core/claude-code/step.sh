#!/bin/bash

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.

function ih::setup::core.claude-code::help() {
  echo 'Install Claude Code and sign in

    This step will:
    - Keep any Claude Code install you already have (npm, brew, or native)
    - Otherwise install Claude Code with the native installer, which updates itself
    - Put ~/.local/bin on your PATH for the native install
    - Start the Claude Code sign-in if you are not signed in'
}

function ih::setup::core.claude-code::test() {
  if ! ih::file::check-shell-defaults "$IH_CORE_LIB_DIR/core/claude-code/default"; then
    ih::log::debug "Claude Code shell defaults are not installed"
    return 1
  fi

  if ! ih::claude::is-installed; then
    ih::log::debug "claude is not on the PATH or in ~/.local/bin"
    return 1
  fi

  if ! ih::claude::is-signed-in; then
    ih::log::debug "Claude Code is not signed in"
    return 1
  fi
}

function ih::setup::core.claude-code::deps() {
  echo "core.shell"
}

function ih::setup::core.claude-code::install() {
  ih::file::sync-shell-defaults "$IH_CORE_LIB_DIR/core/claude-code/default"
  export IH_WANT_RE_SOURCE=1

  if ! ih::claude::is-installed; then
    ih::log::info "Installing Claude Code with the native installer"
    if ! curl -fsSL https://claude.ai/install.sh | bash; then
      ih::log::error "The Claude Code installer failed"
      return 1
    fi
    ih::claude::ensure-path
    if ! ih::claude::is-installed; then
      ih::log::error "The installer finished but claude is not in ~/.local/bin"
      return 1
    fi
  fi

  if ih::claude::is-signed-in; then
    return 0
  fi

  # Sign-in opens a browser and waits for the engineer, so it only runs in a terminal.
  if [ ! -t 0 ] || [ ! -t 1 ]; then
    ih::log::warn "Claude Code is not signed in. Run 'claude auth login' in a terminal."
    return 1
  fi

  ih::log::info "Signing in to Claude Code. Use your Included Health account."
  claude auth login
}
