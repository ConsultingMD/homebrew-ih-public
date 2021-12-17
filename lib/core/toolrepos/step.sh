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
  if [ ! -d "${GR_HOME}/engineering" ]; then
    return 1
  fi

  if [ ! -d "${GR_HOME}/image-builder" ]; then
    return 1
  fi

  return 0
}

function ih::setup::core.toolrepos::deps() {
  # echo "other steps"
  echo "core.github"
}

function ih::setup::core.toolrepos::install() {

  mkdir -p "${GR_HOME}"

  if [ ! -d "${GR_HOME}/engineering" ]; then
    ih::log::info "Cloning engineering repo..."
    git clone git@github.com:ConsultingMD/engineering.git --filter=blob:limit=1m --depth=5 "${GR_HOME}/engineering" || return
  fi

  if [ ! -d "${GR_HOME}/image-builder" ]; then
    ih::log::info "Cloning image-builder repo.."
    git clone git@github.com:ConsultingMD/image-builder.git --filter=blob:limit=1m --depth=5 "${GR_HOME}/image-builder" || return
  fi

  export IH_WANT_RE_SOURCE=1

  cp -f "$IH_CORE_LIB_DIR/core/toolrepos/default/10_toolrepos.sh" "$IH_DEFAULT_DIR/10_toolrepos.sh"
}
