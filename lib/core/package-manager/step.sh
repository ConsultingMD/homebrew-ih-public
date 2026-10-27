#!/bin/bash

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.

PM_CHOICE_PATH="$IH_DIR/package-manager"
TOOL_VERSIONS_TEMPLATE_PATH="$IH_CORE_LIB_DIR/core/package-manager/.tool-versions"

# shellcheck source=/dev/null
. "$IH_CORE_LIB_DIR/core/package-manager/asdf/asdf.sh"
# shellcheck source=/dev/null
. "$IH_CORE_LIB_DIR/core/package-manager/mise/mise.sh"

# Echoes the package manager to use: mise or asdf. The first match wins:
#   1. IH_PACKAGE_MANAGER
#   2. The choice saved in ~/.ih/package-manager
#   3. A tool that is already installed (asdf first), so ih-setup does not break a working setup
#   4. The answer to a prompt, if $1 is "ask" (the default is mise)
#   5. mise
function ih::pm::choice() {
  local ASK="${1:-}"
  local CHOICE="${IH_PACKAGE_MANAGER:-}"

  if [[ -z "$CHOICE" && -f "$PM_CHOICE_PATH" ]]; then
    CHOICE=$(<"$PM_CHOICE_PATH")
  fi

  if [[ "$CHOICE" != "mise" && "$CHOICE" != "asdf" ]]; then
    if command -v asdf >/dev/null || [[ -d "$HOME/.asdf" ]]; then
      CHOICE=asdf
    elif command -v mise >/dev/null; then
      CHOICE=mise
    elif [[ "$ASK" == "ask" ]]; then
      CHOICE=$(ih::ask::choice "Which package manager do you want to use? Choose mise unless it gives you a problem, then choose asdf." mise asdf)
    else
      CHOICE=mise
    fi
  fi

  echo "$CHOICE"
}

function ih::setup::core.package-manager::help() {
  local CURRENT_VERSIONS
  CURRENT_VERSIONS=$(awk -v fmt="           %s %s\n" '{ printf fmt, $1, $2}' <"$TOOL_VERSIONS_TEMPLATE_PATH")
  echo "Install a package manager (mise or asdf) and common tools, and wire it into the shell

    This step will:
        - Ask which package manager you want, mise (default, recommended) or asdf
          (set IH_PACKAGE_MANAGER=asdf or IH_PACKAGE_MANAGER=mise to skip the question)
        - Keep the one you already have installed, if any
        - Install mise with Homebrew, or asdf by cloning into $HOME/.asdf
        - Wire the package manager into the shell
        - Install default versions for commonly used apps:
${CURRENT_VERSIONS}
    "
}

function ih::setup::core.package-manager::test() {
  case "$(ih::pm::choice)" in
    asdf) ih::pm::asdf::test ;;
    *) ih::pm::mise::test ;;
  esac
}

function ih::setup::core.package-manager::deps() {
  echo "core.shell core.git"
}

function ih::setup::core.package-manager::install() {
  local CHOICE
  CHOICE=$(ih::pm::choice ask)

  mkdir -p "$(dirname "$PM_CHOICE_PATH")"
  echo "$CHOICE" >"$PM_CHOICE_PATH"
  ih::log::info "Using $CHOICE as the package manager"

  case "$CHOICE" in
    asdf) ih::pm::asdf::install ;;
    *) ih::pm::mise::install ;;
  esac
}
