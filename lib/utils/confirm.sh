#!/bin/bash

function ih::ask::confirm() {
  local action="${1}"
  local response
  echo "${action}"

  if [[ $SKIP_CONFIRMATION -eq 1 ]]; then
    return 0
  fi

  echo "OK to proceed? (y/N)"
  read -rsn1 response
  case "${response}" in
    [yY])
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# Prints the content of $1 and then asks the
# user to choose yes, no, or retry.
# If the user chooses yes, returns 0
# If the user chooses retry, returns 1
# If the user chooses no, returns 2
function ih::ask::yes-no-retry() {
  local action="${1}"
  local response
  echo "${action}"

  echo "Yes/No/Retry (y/n/r)"
  read -rsn1 response
  case "${response}" in
    [yY])
      return 0
      ;;
    [rR])
      return 1
      ;;
    *)
      return 2
      ;;
  esac
}
# Prints the content of $1 and then asks the
# user to choose retry or cancel.
# If the user chooses cancel, returns 1
# Otherwise, returns 0
function ih::ask::retry-cancel() {
  local action="${1}"
  local response
  echo "${action}"

  echo "Retry/Cancel (R/c)"
  read -rsn1 response
  case "${response}" in
    [cC])
      return 1
      ;;
    *)
      return 0
      ;;
  esac
}
# Prints the prompts of $1 and allows the
# user to press enter to continue, or
# Ctrl+C to cancel.
function ih::ask::enter-continue() {
  local prompt="${1}"
  read -rp "$prompt"
}

# Prints the prompt $1 and asks the user to choose one of the remaining
# arguments. Pressing enter picks the first option, which is the default.
# Prints the chosen option on stdout, so the prompt goes to stderr.
# With IH_NO_CONFIRM=1 it skips the prompt and prints the default.
function ih::ask::choice() {
  local prompt="${1}"
  shift
  local default="${1}"
  local response option

  if [[ $IH_NO_CONFIRM -eq 1 ]]; then
    echo "${default}"
    return 0
  fi

  while true; do
    read -rp "${prompt} ($*; default ${default}): " response </dev/tty >&2
    response="${response:-$default}"
    for option in "$@"; do
      if [[ "${response}" == "${option}" ]]; then
        echo "${option}"
        return 0
      fi
    done
    echo "Please enter one of: $*" >&2
  done
}
