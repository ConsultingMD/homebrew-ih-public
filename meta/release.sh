#!/bin/bash

# This script creates and pushes a release
# It takes one parameter: the version number of the release
# The current version number is in ih-core/bin/VERSION
# This command will fail if the repo is dirty, or if the release already exists.
# It will cause a commit with the new version updates

THIS_DIR=$(dirname $(realpath "$0"))

VERSION=${1:?"You must provide a version for the release"}

if [[ $(git status --short) != '' ]]; then
  echo 'Working directory is dirty, commit and push everything before making release.'
  exit 1
fi

# We want to abort if any of the following commands fail
set -e

# Update the formula and the version file with the new version
URL="https://github.com/ConsultingMD/homebrew-ih-public/archive/refs/tags/$VERSION.tar.gz"
sed -i '' "s/^  url.*/  url \"${URL//\//\\/}\""/ "$THIS_DIR/../formula/ih-core.rb"
echo "$VERSION" > "$THIS_DIR/../ih-core/bin/VERSION"

# If updating the files caused a change then commit that change.
if [[ $(git status --short) != '' ]]; then
    git add "$THIS_DIR/../formula/ih-core.rb"
    git add "$THIS_DIR/../ih-core/bin/VERSION"
    git commit -m "Bump version to $VERSION"
fi
git tag -a "$VERSION" -m "Release version $VERSION"
git push


BRANCH=$(git rev-parse --abbrev-ref HEAD)

gh release create "$VERSION" -t "$VERSION" --notes "Release version $VERSION"  --target "$BRANCH" ./ih-core/bootstrap.sh

set +e