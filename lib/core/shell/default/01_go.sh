#!/usr/bin/env bash

# Enable module support (this is the default behavior)
export GO111MODULE=on
# Ensure that the go binary directory is stable
# (i.e., not tied to the version of Go you're using via asdf
export GOBIN="${HOME}/go/bin"
# Add the go binary directory to the PATH
# so go install will work.
export PATH=$PATH:"${GOBIN}"
# Allow importing of private repos in Go
export GOPRIVATE='github.com/ConsultingMD/*'
# Unset GOROOT to prevent IDE-injected values from messing
# up the behavior of Go tooling by overriding it.
unset GOROOT
