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

ih::arch::check_macos_version_compatibility() {
  local required_version="$1"
  local current_version=$(ih::arch::get_macos_version)

  # Splitting the current and required versions into major and minor components
  IFS='.' read -r current_major current_minor _ <<< "$current_version"
  IFS='.' read -r required_major required_minor _ <<< "$required_version"

  # Ensure variables are integers (default to 0 if empty for robust comparison)
  current_major=${current_major:-0}
  current_minor=${current_minor:-0}
  required_major=${required_major:-0}
  required_minor=${required_minor:-0}

  if (( current_major > required_major )) || { (( current_major == required_major )) && (( current_minor >= required_minor )); }; then
    return 0 # meets minimum requirement
  else
    ih::log::error "macOS version $required_version or higher is required. Current version: $current_version."
    return 1
  fi
}

ih::arch::is_recent_apple_silicon() {
  local hw_model=$(sysctl -n machdep.cpu.brand_string)
  # Check macOS version compatibility with VZ for M2+ Macs (VZ requires macOS >=13.3)
  [[ "$hw_model" =~ "Apple M[2-9]" ]]
}
