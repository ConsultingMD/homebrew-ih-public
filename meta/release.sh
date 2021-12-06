#!/bin/bash

VERSION=${1:?"You must provide a version for the release"}

if [[ $(git status --short) != '' ]]; then
  echo 'Working directory is dirty, commit and push everything before making release.'
  exit 1
fi

set -e

git tag -a "$VERSION"
git push

set +e

PACKAGE="./dist/ih-core.${VERSION}.tar.gz"

tar -czvf "$PACKAGE" ./ih-core

gh release create "$VERSION" -t "$VERSION" "$PACKAGE"