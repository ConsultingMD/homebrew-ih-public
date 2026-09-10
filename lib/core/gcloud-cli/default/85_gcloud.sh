#!/bin/bash

# The gcloud-cli cask symlinks gcloud/gsutil/bq into brew's bin, but components
# installed with `gcloud components install` (gke-gcloud-auth-plugin, etc.)
# land in the SDK's own bin directory and are not symlinked.
GCLOUD_BIN="$(brew --prefix)/share/google-cloud-sdk/bin"
if [ -d "$GCLOUD_BIN" ] && [[ ":$PATH:" != *":$GCLOUD_BIN:"* ]]; then
  export PATH="$GCLOUD_BIN:$PATH"
fi
