#!/bin/bash

# PATH helpers for the step scripts and the agent updater.
# Native installers (claude, twg) put their CLIs in ~/.local/bin. The core.shell
# defaults put that directory on the PATH of new shells; these helpers do the same
# for the running process, so a CLI installed in this run is found right away.

# Puts ~/.local/bin at the front of the PATH if it is not already on the PATH.
function ih::path::ensure-local-bin() {
  case ":${PATH}:" in
    *":${HOME}/.local/bin:"*) ;;
    *) export PATH="${HOME}/.local/bin:${PATH}" ;;
  esac
}

# Returns 0 if the command $1 is on the PATH or in ~/.local/bin.
function ih::path::has-command() {
  ih::path::ensure-local-bin
  command -v "${1:?command is required}" >/dev/null 2>&1
}
