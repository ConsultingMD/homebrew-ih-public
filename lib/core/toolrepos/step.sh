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

function ih::setup::core.toolrepos::deps() {
  # echo "other steps"
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
    ih::log::info "Cloning engineering repo..."
    git clone git@github.com:ConsultingMD/engineering.git --filter=blob:limit=1m --depth=5 "${GR_HOME}/engineering" || return
  fi

  if [ ! -d "${GR_HOME}/image-builder" ]; then
    if [ "$1" == "test" ]; then
      return 1
    fi
    ih::log::info "Cloning image-builder repo.."
    git clone git@github.com:ConsultingMD/image-builder.git --filter=blob:limit=1m --depth=5 "${GR_HOME}/image-builder" || return
  fi

  if [ ! -d "${GR_HOME}/kore" ]; then
    if [ "$1" == "test" ]; then
      return 1
    fi
    ih::log::info "Cloning kore repo.."
    git clone git@github.com:ConsultingMD/kore.git --filter=blob:limit=1m --depth=5 "${GR_HOME}/kore" || return
  fi

  local toolsrepo_src_path="$IH_CORE_LIB_DIR/core/toolrepos/default/10_toolrepos.sh"
  local toolsrepo_tgt_path="$IH_DEFAULT_DIR/10_toolrepos.sh"

  if [ "$1" = "test" ]; then
    ih::file::check-file-in-sync "$toolsrepo_src_path" "$toolsrepo_tgt_path"
    return
  fi

  export IH_WANT_RE_SOURCE=1

  cp -f "$toolsrepo_src_path" "$toolsrepo_tgt_path"

  ih::setup::core.toolrepos::set-auto-update-repositories-job

}

function ih::setup::core.toolrepos::set-auto-update-repositories-job() {

  local THIS_DIR="$IH_CORE_LIB_DIR/core/toolrepos/autoupdate"

  PLIST_FILE="com.includedhealth.auto-update-repositories"
  LAUNCH_AGENTS_PATH="${HOME}/Library/LaunchAgents/${PLIST_FILE}.plist"
  
  sed "s/\$IH_HOME/${GR_HOME}/g" "${THIS_DIR}/${PLIST_FILE}.plist" > "${LAUNCH_AGENTS_PATH}"

  if launchctl list | grep -q ${PLIST_FILE} ; then
    launchctl unload "${LAUNCH_AGENTS_PATH}"
  fi

  launchctl load "${LAUNCH_AGENTS_PATH}"

}
