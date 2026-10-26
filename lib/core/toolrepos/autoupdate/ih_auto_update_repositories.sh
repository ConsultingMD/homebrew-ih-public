#!/bin/bash

set -Eeuo pipefail

# shellcheck source=/dev/null
. "${IH_CORE_LIB_DIR:-$(dirname "$(dirname "$(dirname "$(dirname "$0")")")")}/utils/notify.sh"

LOG_DIR="${HOME}/Library/Logs/ih-setup"
NOTIFY_SENTINEL="${LOG_DIR}/.notified-repo-updater"
mkdir -p "$LOG_DIR" || true

function on_exit() {
  local status=$?
  if [ $status -ne 0 ]; then
    local title="IH Setup background updater failed"
    local body="The repo-updater daemon failed. Open ~/Library/Logs/ih-setup/repo-updater.log for details. If you can’t resolve it, upload the last 200 lines to Slack channel #C03GXCDA48Y."
    if ih::notify::throttle_by_file "$NOTIFY_SENTINEL" 21600; then
      ih::notify::mac "$title" "$body"
    fi
  fi
  return $status
}
trap on_exit EXIT

# Allow easy manual verification of notifications (after trap so it fires)
if [ "${SIMULATE_FAILURE:-}" = "1" ]; then
  echo "Simulated failure requested via SIMULATE_FAILURE=1" >&2
  exit 1
fi

# These repos are needed to be kept up to date
# as they are used daily in the SDLC.
repos=(engineering image-builder janus temporal kafka ih-observability)

for repo in "${repos[@]}"; do
  if [[ ! -d "$IH_HOME/$repo" ]]; then
    echo "Skipping $repo (not cloned)" >&2
    continue
  fi

  cd "$IH_HOME/$repo" || continue

  currentBranch=$(git branch --show-current)
  defaultBranch=$(git branch -rl '*/HEAD' | rev | cut -d/ -f1 | rev)

  # Do git pull only if the default branch is checked out.
  if [[ "$currentBranch" == "$defaultBranch" ]]; then
    git pull
  else
    # Try to pull the latest into the current branch instead
    git pull origin "$defaultBranch" --ff-only --autostash
  fi

done
