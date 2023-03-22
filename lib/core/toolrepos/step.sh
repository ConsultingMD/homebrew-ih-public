#!/bin/bash

function ih::setup::core.toolrepos::help() {
  echo "Clone engineering repo to access additional scripts

    This step will:
    - Clone the ConsultingMD/engineering repo
      This repo contains tools for
    - Clone the ConsultingMD/image-builder repo
      This repo contains tools for building images
      and for setting up development enviroments"
}

function ih::setup::core.toolrepos::test() {
  ih::setup::core.toolrepos::test-or-install "test"

}

# echo "other steps"
function ih::setup::core.toolrepos::deps() {
  echo "core.github"
}
function ih::setup::core.toolrepos::install() {
  ih::setup::core.toolrepos::test-or-install "install"

}

# If $1 is "test", this will check if install is needed and return 1 if it is.
# Otherwise, this will install the repos.

function ih::setup::core.toolrepos::test-or-install() {
  if [ "$1" == "install" ]; then
    mkdir -p "${GR_HOME}"
  fi

  if [ ! -d "${GR_HOME}/engineering" ]; then
    if [ "$1" == "test" ]; then
      return 1
    fi
    ih-sync-repo -r engineering
  fi

  if [ ! -d "${GR_HOME}/image-builder" ]; then
    if [ "$1" == "test" ]; then
      return 1
    fi
    ih::log::info "Cloning image-builder repo.."
    ih-sync-repo -r image-builder
  fi

  PRE_COMMIT_HOOK_DST="${IH_DIR}/git-template/hooks/pre-commit"
  if [ ! -f "$PRE_COMMIT_HOOK_DST" ]; then
    if [ "$1" == "test" ]; then
      return 1
    fi

    ih-sync-repo -r image-builder
    ih::log::info "Installing ih-pre-commit hook everywhere..."
    export IMAGE_BUILDER_ROOT="${IH_HOME}/image-builder"
    "$IMAGE_BUILDER_ROOT/bin/ih-pre-commit" install --global
  fi

  if [ ! -d "${GR_HOME}/kore" ]; then
    if [ "$1" == "test" ]; then
      return 1
    fi
    git clone git@github.com:ConsultingMD/kore.git --filter=blob:limit=1m --depth=5 "${GR_HOME}/kore" || return
    ih::log::info "Cloning kore repo.."
  fi

  local toolsrepo_src_path="$IH_CORE_LIB_DIR/core/toolrepos/default/10_toolrepos.sh"
  local toolsrepo_tgt_path="$IH_DEFAULT_DIR/10_toolrepos.sh"

  if [ "$1" = "test" ]; then
    return
    ih::file::check-file-in-sync "$toolsrepo_src_path" "$toolsrepo_tgt_path"
  fi

  export IH_WANT_RE_SOURCE=1

  cp -f "$toolsrepo_src_path" "$toolsrepo_tgt_path"
}
