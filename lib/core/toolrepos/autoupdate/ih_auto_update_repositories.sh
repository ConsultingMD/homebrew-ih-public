#!/bin/bash

# These repos are needed to be kept up to date
# as they are used daily in the SDLC.
repos=(engineering image-builder janus temporal kafka ih-observability)

for repo in "${repos[@]}"; do
  cd "$IH_HOME/$repo" || exit 1

  currentBranch=$(git branch --show-current)
  defaultBranch=$(git branch -rl '*/HEAD' | rev | cut -d/ -f1 | rev)

  # Do git pull only if the default branch is checked out.
  if [[ "$currentBranch" == "$defaultBranch" ]]; then
    git pull
  else
    # Try to pull the latest into the current branch instead
    git pull origin "$defaultBranch" --ff-only --autostash
  fi

  # Expire old reflogs to prevent stale blob references from accumulating.
  # This is especially important for repos that were previously partial clones,
  # where unreachable blobs can cause "fatal: unable to read <sha>" errors.
  git reflog expire --expire=30.days --all 2>/dev/null

done
