#!/bin/bash

# These are functions for running commands with different architectures

# Invokes its args as a command in an x86 (intel) shell
ih::arch::x86() {
  arch -x86_64 "$SHELL" -c "${*}"
}

# Invokes its args as a command in an arm64 (M1) shell
ih::arch::amd64() {
  arch -arm64 "$SHELL" -c "${*}"
}

# Invokes the x86 mode of brew
ih::arch::ibrew() {
  /usr/local/bin/brew "${@}"
}

# Invokes the arm64 mode of brew.
ih::arch::mbrew() {
  /opt/homebrew/bin/brew "${@}"
}
