#!/bin/bash

repos=(engineering image-builder)

for repo in "${repos[@]}" ; do
    cd "$IH_HOME/$repo" || exit 1

    # Saves our current and main/master branch of the repository
    currentBranch=$(git branch --show-current)
    mainBranch=$(git branch | tr " " "\n" | grep -E "(main|master)")

    # If we cannot find the main branch, skip over this repository
    if [[ -z "$mainBranch" ]]; then
        echo "Failed to find the main branch, skipping this git repository"
        continue
    fi

    # Switch to our main branch
    if [[ "$currentBranch" != "$mainBranch" ]]; then
        git checkout "$mainBranch"
    fi

    # Save any pending changes
    gitStash=$(git stash)
    gitPull=$(git pull)


    # Short-circuit if we have the latest changes
    if [[ "$gitPull" == "Already up to date." && "$currentBranch" != "$mainBranch" ]]; then
        git checkout "$currentBranch"
        continue
    fi

    # Revert pending changes
    if [[ "$gitStash" != "No local changes to save" ]]; then
        git stash pop
    fi

    # Switch back to our existing branch
    if [[ "$currentBranch" != "$mainBranch" ]]; then
        git checkout "$currentBranch"
    fi
done
