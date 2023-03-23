#!/bin/bash

repos=(engineering image-builder)

for repo in "${repos[@]}" ; do
    cd "$IH_HOME/$repo" || exit 1

    currentBranch=$(git branch --show-current)
    defaultBranch=$(git  branch -rl '*/HEAD' | rev | cut -d/ -f1 | rev)

    # Do git pull only if the default branch is checked out.
    if [[ "$currentBranch" == "$defaultBranch" ]]; then
        git pull
    fi

done
