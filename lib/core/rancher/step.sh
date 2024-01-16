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

  # Use vz instead of qemu on macOS 13.3 to resolve m3 mac issues.
  # See: https://github.com/lima-vm/lima/issues/1996
  # Also: https://github.com/rancher-sandbox/rancher-desktop/blob/fcffd3cc071a9414dcf03c895792b5142116ffd4/pkg/rancher-desktop/main/commandServer/settingsValidator.ts#L320-L330
  local macos_version=$(ih::arch::get_macos_version)
  if (( $(echo "$macos_version >= 13.3" | bc -l) )); then
    if grep -q "<string>vz</string>" "$PLIST_DST"; then
      ih::log::debug "The PLIST file already uses 'vz' for Virtualization."
    else
      ih::log::debug "The PLIST file needs to be updated to use 'vz'."
      return 1
    fi
  fi

  return 0
}

function ih::setup::core.rancher::deps() {
  echo "core.shell"
}

function ih::setup::core.rancher::install() {
  local THIS_DIR="$IH_CORE_LIB_DIR/core/rancher"

  cp -f "$RANCHER_AUGMENT_SRC" "$RANCHER_AUGMENT_DST"

  echo "A configuration file for Rancher Desktop will be copied to your system"
  echo "You may be required to enter your password"
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

  # Check if Rancher was installed manually with brew
  if [ $RANCHER_INSTALLED -eq 0 ]; then
    echo "Rancher Desktop was installed previously with brew command. In order to avoid any conflicts this script will uninstall that package".
    echo "You may be required to enter your password"
    brew uninstall rancher
  fi

  CASKSUCCEEDED=1
  # Installation and configuration of Rancher Desktop
  for _ in 1 2 3; do

    # Check if we have a Mac M1 and the terminal is running  over x86
    if [[ $(sysctl -n sysctl.proc_translated) -eq 1 ]] && [ $(arch) = "i386" ]; then
      arch -arm64 -c brew reinstall ih-rancher
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

    # Use vz instead of qemu on macOS 13.3 to resolve m3 mac issues.
    local macos_version=$(ih::arch::get_macos_version)
    if (( $(echo "$macos_version >= 13.3" | bc -l) )); then
      if ! grep -q "<string>vz</string>" "$PLIST_DST"; then
        ih::log::debug "Updating PLIST to use 'vz' for Virtualization."
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
