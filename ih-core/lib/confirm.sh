#!/bin/bash

function ih::private::confirm() {
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
