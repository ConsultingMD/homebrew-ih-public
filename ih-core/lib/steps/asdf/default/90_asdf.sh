#!/bin/bash

# This adds the asdf shims to the shell.

ASDF_SH=$(brew --prefix asdf)/libexec/asdf.sh
if [ -f "$ASDF_SH" ]; then
  # shellcheck disable=SC1090
  . "$ASDF_SH"
fi
