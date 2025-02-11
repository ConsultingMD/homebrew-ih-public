#!/bin/bash

function ih::setup::core.toolrepos::help() {
  echo "Clone engineering repo to access additional scripts

    This step will:
    - Clone the ConsultingMD/engineering repo
      This repo contains tools for
    - Clone the ConsultingMD/image-builder repo
      This repo contains tools for building images
      and for setting up development environments"
}

function ih::setup::core.toolrepos::test() {
  ih::setup::core.toolrepos::test-or-install "test"
}

function ih::setup::core.toolrepos::deps() {
  echo "core.github"
}

function ih::setup::core.toolrepos::install() {
  ih::setup::core.toolrepos::test-or-install "install"
}

function ih::setup::core.toolrepos::create_temp_plist() {
  local TEMP_PLIST_DST
  TEMP_PLIST_DST=$(mktemp /tmp/ih_auto_update_repositories.XXXXXX)

  local GR_HOME_ESC
  # shellcheck disable=SC2001
  GR_HOME_ESC=$(echo "$GR_HOME" | sed 's_/_\\/_g')

  local IH_CORE_LIB_DIR_ESC
  # shellcheck disable=SC2001
  IH_CORE_LIB_DIR_ESC=$(echo "$IH_CORE_LIB_DIR" | sed 's_/_\\/_g')

  sed "s/\$IH_HOME/${GR_HOME_ESC}/g; s/\$IH_CORE_LIB_DIR/${IH_CORE_LIB_DIR_ESC}/g" \
    "$IH_CORE_LIB_DIR/core/toolrepos/autoupdate/com.includedhealth.auto-update-repositories.plist" >"$TEMP_PLIST_DST"

  echo "$TEMP_PLIST_DST"
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
    git clone git@github.com:ConsultingMD/engineering.git --filter=blob:limit=1m "${GR_HOME}/engineering" || return
  fi

  if [ ! -d "${GR_HOME}/image-builder" ]; then
    if [ "$1" == "test" ]; then
      return 1
    fi
    ih::log::info "Cloning image-builder repo.."
    git clone git@github.com:ConsultingMD/image-builder.git --filter=blob:limit=1m "${GR_HOME}/image-builder" || return
  fi

  if [ ! -d "${GR_HOME}/kore" ]; then
    if [ "$1" == "test" ]; then
      return 1
    fi
    ih::log::info "Cloning kore repo.."
    git clone git@github.com:ConsultingMD/kore.git --filter=blob:limit=1m --depth=5 "${GR_HOME}/kore" || return
  fi

  local plist_tgt_path="$HOME/Library/LaunchAgents/com.includedhealth.auto-update-repositories.plist"

  # Create temporary plist with variables replaced
  local temp_plist
  temp_plist=$(ih::setup::core.toolrepos::create_temp_plist)

  if [ ! -f "$plist_tgt_path" ] || ! ih::file::check-file-in-sync "$temp_plist" "$plist_tgt_path"; then
    if [ "$1" == "test" ]; then
      rm -f "$temp_plist"
      return 1
    fi
    mkdir -p "$(dirname "$plist_tgt_path")"
    cp -f "$temp_plist" "$plist_tgt_path"
    ih::log::info "Plist file updated."
    ih::setup::core.toolrepos::set-auto-update-repositories-job
  fi
  rm -f "$temp_plist"

  local toolsrepo_src_path="$IH_CORE_LIB_DIR/core/toolrepos/default/10_toolrepos.sh"
  local toolsrepo_tgt_path="$IH_DEFAULT_DIR/10_toolrepos.sh"
  if ! ih::file::check-file-in-sync "$toolsrepo_src_path" "$toolsrepo_tgt_path"; then
    if [ "$1" = "test" ]; then
      return 1
    fi
    cp -f "$toolsrepo_src_path" "$toolsrepo_tgt_path"
    export IH_WANT_RE_SOURCE=1
  fi

  PRE_COMMIT_HOOK_DST="${IH_DIR}/git-template/hooks/pre-commit"
  if [ ! -f "$PRE_COMMIT_HOOK_DST" ]; then
    if [ "$1" == "test" ]; then
      return 1
    fi

    export IMAGE_BUILDER_ROOT="${IH_HOME}/image-builder"
    export PATH="${IMAGE_BUILDER_ROOT}/bin:${PATH}"
    export PATH="${IH_HOME}/engineering/bin:${PATH}"
    (
      cd "$IMAGE_BUILDER_ROOT" || exit
      CURRENT_BRANCH=$(git branch --show-current)
      if [ "$CURRENT_BRANCH" != "master" ]; then
        ih::log::warn "You have a non-master branch of image-builder checked out.
You will need to check out and pull the master branch and run
'ih-pre-commit install --global'
manually in order to have pre-commit configured correctly."
        return 1
      else
        git pull
        ih::log::info "Installing ih-pre-commit hook everywhere..."
        "$IMAGE_BUILDER_ROOT/bin/ih-pre-commit" install --global
      fi
    )
  fi
}

function ih::setup::core.toolrepos::set-auto-update-repositories-job() {
  local PLIST_FILE="com.includedhealth.auto-update-repositories"
  local LAUNCH_AGENTS_PATH="${HOME}/Library/LaunchAgents/${PLIST_FILE}.plist"

  if launchctl list | grep -e ${PLIST_FILE}; then
    launchctl unload "${LAUNCH_AGENTS_PATH}"
  fi

  launchctl load "${LAUNCH_AGENTS_PATH}"

  ih::log::info "Plist file loaded successfully: $LAUNCH_AGENTS_PATH"
}
