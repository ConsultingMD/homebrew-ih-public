#!/bin/bash

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.

GCLOUD_SH_TEMPLATE_PATH="$IH_CORE_LIB_DIR/core/gcloud-cli/default/85_gcloud.sh"
GCLOUD_SH_PATH="$IH_DEFAULT_DIR/85_gcloud.sh"

function ih::setup::core.gcloud-cli::help() {
  echo "Install the Google Cloud CLI

    This step will:
        - Install the gcloud-cli Homebrew cask (gcloud, gsutil, bq)
        - Add the Google Cloud SDK bin directory to your PATH so components
          installed with 'gcloud components install' are available
    "
}

# Check if the step has been installed and return 0 if it has.
# Otherwise return 1.
function ih::setup::core.gcloud-cli::test() {
  if ! brew list --cask gcloud-cli >/dev/null 2>&1; then
    ih::log::debug "gcloud-cli cask is not installed"
    return 1
  fi

  if ! ih::file::check-file-in-sync "$GCLOUD_SH_TEMPLATE_PATH" "$GCLOUD_SH_PATH"; then
    ih::log::debug "gcloud augment file is out of sync with template"
    return 1
  fi

  return 0
}

function ih::setup::core.gcloud-cli::deps() {
  echo "core.shell"
}

function ih::setup::core.gcloud-cli::install() {
  ih::log::info "Installing the gcloud-cli cask"
  if ! brew install --cask gcloud-cli; then
    ih::log::error "Failed to install the gcloud-cli cask"
    return 1
  fi

  ih::log::info "Copying augment file for shell"
  cp -f "$GCLOUD_SH_TEMPLATE_PATH" "$GCLOUD_SH_PATH"

  export IH_WANT_RE_SOURCE=1
}
