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
