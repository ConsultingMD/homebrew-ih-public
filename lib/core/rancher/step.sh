#!/bin/bash

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.

function ih::setup::core.rancher::help() {
  echo 'Install Rancher Desktop as an alternative to Docker Desktop'
}

RANCHER_AUGMENT_SRC="$IH_CORE_LIB_DIR/core/rancher/default/11_rancher.sh"
RANCHER_AUGMENT_DST="$IH_DEFAULT_DIR/11_rancher.sh"

PLIST_SRC="$IH_CORE_LIB_DIR/core/rancher/io.rancherdesktop.profile.defaults.plist"
PLIST_DST="$HOME/Library/Preferences/io.rancherdesktop.profile.defaults.plist"

# Check if the step has been installed and return 0 if it has.
# Otherwise return 1.
function ih::setup::core.rancher::test() {

  # Check if Rancher was installed manually
  brew list rancher >/dev/null 2>&1
  RANCHER_INSTALLED=$?

  #Check if IH Rancher is already installed
  brew list ih-rancher >/dev/null 2>&1
  IH_RANCHER_INSTALLED=$?

  if [ $RANCHER_INSTALLED -eq 0 ]; then
    ih::log::debug "Rancher Desktop was installed manually and should be uninstalled"
    return 1
  fi

  if [ $IH_RANCHER_INSTALLED -eq 1 ]; then
    ih::log::debug "IH-Rancher should be listed as a cask"
    return 1
  fi

  if ! ih::file::check-file-in-sync "$RANCHER_AUGMENT_SRC" "$RANCHER_AUGMENT_DST"; then
    ih::log::debug "Augment script not in sync"
    return 1
  fi

  if [ ! -f "$PLIST_DST" ]; then
    ih::log::debug "The PLIST file is missing."
    return 1
  fi

  if ! ih::file::check-file-in-sync "$PLIST_SRC" "$PLIST_DST"; then
    ih::log::debug "The PLIST file is out of sync."
    return 1
  fi

  # Use vz (requires macOS >=13.3) instead of qemu on M3 macs to resolve issues.
  # More details: https://github.com/lima-vm/lima/issues/1996
  local macos_version=$(ih::arch::get_macos_version)
  if ih::arch::is_m3_mac; then
    if (( $(echo "$macos_version < 13.3" | bc -l) )); then
      ih::log::error "macOS version 13.3 or higher is required for M3 Macs."
      return 1
    elif ! grep -q "<string>vz</string>" "$PLIST_DST"; then
      ih::log::debug "The PLIST file needs to be updated to use 'vz' for M3 Macs."
      return 1
    fi
  fi

  return 0
}

function ih::setup::core.rancher::deps() {
  echo "core.shell"
}

function ih::setup::core.rancher::install() {
  # Clean up old docker symlink to prevent "Permission denied" error
  # More details: https://stackoverflow.com/a/75141533
  local SYMLINK_PATH="/usr/local/lib/docker/cli-plugins"
  if [ -L "$SYMLINK_PATH" ]; then
    local TARGET_PATH=$(readlink "$SYMLINK_PATH")
    if [ ! -d "$TARGET_PATH" ]; then
      sudo rm -f "$SYMLINK_PATH"
      ih::log::info "Removed broken symlink from old docker install at $SYMLINK_PATH"

      brew cleanup
      ih::log::info "Homebrew cleanup completed."
    fi
  fi

  cp -f "$RANCHER_AUGMENT_SRC" "$RANCHER_AUGMENT_DST"

  echo "A configuration file for Rancher Desktop will be copied to your system"
  echo "You may be required to enter your password"
  local THIS_DIR="$IH_CORE_LIB_DIR/core/rancher"
  sudo cp "${THIS_DIR}/io.rancherdesktop.profile.defaults.plist" "$PLIST_DST"

  # Check if Rancher was installed manually
  brew list rancher >/dev/null 2>&1
  RANCHER_INSTALLED=$?

  #Check if IH Rancher is already installed
  brew list ih-rancher >/dev/null 2>&1
  IH_RANCHER_INSTALLED=$?

  # If rancher or ih-rancher is already installed  reset to factory
  if [ $RANCHER_INSTALLED -eq 0 ] || [ $IH_RANCHER_INSTALLED -eq 0 ]; then
    $(/Applications/Rancher\ Desktop.app/Contents/Resources/resources/darwin/bin/rdctl factory-reset)
  fi
  
  # If Rancher Desktop isn't installed via brew or ih-rancher, check for the app and remove it
  # More info: https://docs.rancherdesktop.io/getting-started/installation/#installing-rancher-desktop-on-macos
  RANCHER_APP_PATH="/Applications/Rancher Desktop.app"
  if [ $RANCHER_INSTALLED -ne 0 ] && [ $IH_RANCHER_INSTALLED -ne 0 ] && [ -d "$RANCHER_APP_PATH" ]; then
      echo "Rancher Desktop application found at $RANCHER_APP_PATH, removing..."
      rm -rf "$RANCHER_APP_PATH"
      if [ $? -ne 0 ]; then
          ih::log::error "Failed to remove $RANCHER_APP_PATH. Please remove it manually."
          return 1
      fi
  fi

  # Check if Rancher was installed manually with brew
  if [ $RANCHER_INSTALLED -eq 0 ]; then
    echo "Rancher Desktop was installed previously with brew command. In order to avoid any conflicts this script will uninstall that package".
    echo "You may be required to enter your password"
    brew uninstall rancher
  fi

  CASKSUCCEEDED=1
  # Installation and configuration of Rancher Desktop
  for _ in 1 2 3; do

    # Check if we have a M1 Mac
    if [ "$(uname -m)" = "arm64" ]; then
      arch -arm64 brew reinstall ih-rancher
    else
      brew reinstall ih-rancher
    fi
    CASKSUCCEEDED=$?
    if [ $CASKSUCCEEDED -eq 0 ]; then
      break
    fi
  done

  # Continue with the setting just if the cask was installed successfully
  if [ $CASKSUCCEEDED -eq 0 ]; then
    rm -rf ~/.rd
    $(/Applications/Rancher\ Desktop.app/Contents/Resources/resources/darwin/bin/rdctl start)
    # Check for docker binary in /usr/local/bin
    # Check if /usr/local/bin/docker exists
    DOCKERBIN=/usr/local/bin/docker
    DOCKERCOMPOSEBIN=/usr/local/bin/docker-compose
    if [ ! -f "$DOCKERBIN" ]; then

      echo "In order to continue with Rancher configuration and be able to use this engine, some IDEs require the creation of symlinks for remote Python interpreters"
      echo "Your password is required for the creation of symlink mentioned above"
      sudo ln -s $HOME/.rd/bin/docker /usr/local/bin/docker
      if [ ! -f "$DOCKERCOMPOSEBIN" ]; then
        sudo ln -s $HOME/.rd/bin/docker-compose /usr/local/bin/docker-compose
      fi
    fi

    # Use vz (requires macOS >=13.3) instead of qemu on M3 macs to resolve issues.
    # More details: https://github.com/lima-vm/lima/issues/1996
    if ih::arch::is_m3_mac; then
      if (( $(echo "$macos_version < 13.3" | bc -l) )); then
        ih::log::error "macOS version 13.3 or higher is required for M3 Macs."
        return 1 # Abort the installation for M3 Macs
      elif ! grep -q "<string>vz</string>" "$PLIST_DST"; then
        ih::log::debug "Updating PLIST to use 'vz' for Virtualization for M3 Macs."
        sudo sed -i '' 's/<string>qemu<\/string>/<string>vz<\/string>/g' "$PLIST_DST"
      fi
    fi

    echo "Rancher Desktop has been installed successfully"
  else
    ih::log::warn "Could not install Rancher Desktop"
    echo "There was an error with Rancher Desktop Installation. Please contact  support
            in the #developer-tools channel in Slack (https://ih-epdd.slack.com/archives/C04LPMF4YPL)"
    return 1
  fi
}
