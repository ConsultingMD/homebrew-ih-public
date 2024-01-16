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

ih::arch::get_macos_version() {
  sw_vers -productVersion | awk -F '.' '{ printf("%d.%d\n", $1, $2) }'
}

ih::arch::is_m3_mac() {
  local hw_model=$(sysctl -n machdep.cpu.brand_string)
  if [[ "$hw_model" == *"M3"* ]]; then
    return 0  # This is an M3 Mac.
  else
    return 1  # This is not an M3 Mac.
  fi
}
