#!/bin/bash

THIS_DIR=$(dirname $(realpath "$0"))

VERSION=${1:?"You must provide a version for the release"}

if [[ $(git status --short) != '' ]]; then
  echo 'Working directory is dirty, commit and push everything before making release.'
  exit 1
fi

set -e

URL="https://github.com/ConsultingMD/homebrew-ih-public/archive/refs/tags/$VERSION.tar.gz"

sed -i '' "s/^  url.*/  url \"${URL//\//\\/}\""/ "$THIS_DIR/../formula/ih-core.rb"

git add "$THIS_DIR/../formula/ih-core.rb"
git commit -m "Bump version to $VERSION"
git tag -a "$VERSION" -m "Release version $VERSION"
git push

set +e

BRANCH=$(git rev-parse --abbrev-ref HEAD)

gh release create "$VERSION" -t "$VERSION" --notes "Release version $VERSION"  --target "$BRANCH"