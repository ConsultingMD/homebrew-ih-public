#!/bin/bash

function ih::setup::core.github::help() {
  echo "Configure github settings

    This step will:
    - Authenticate you to GitHub via the gh CLI tool
    - Configure your GitHub account to support authenticating with your SSH key
    - Authorize your SSH key for the ConsultingMD organization (SAML SSO)"
}

function ih::setup::core.github::test() {
  # check basic GitHub SSH authentication
  local SSH_RESULT
  SSH_RESULT=$(ssh git@github.com 2>&1)

  if [[ ! $SSH_RESULT =~ "You've successfully authenticated" ]]; then
    return 1
  fi

  # check SAML SSO authorization for ConsultingMD organization
  if ! git ls-remote git@github.com:ConsultingMD/engineering.git &>/dev/null; then
    return 1
  fi

  return 0
}

function ih::setup::core.github::deps() {
  echo "core.shell core.git core.ssh"
}

function ih::setup::core.github::_show_sso_instructions() {
  ih::log::info "Follow these steps:"
  ih::log::info "1. Go to the GitHub SSH keys page"
  ih::log::info "2. Find your SSH key (usually labeled 'Included Health')"
  ih::log::info "3. Click 'Configure SSO' next to your key"
  ih::log::info "4. Select 'ConsultingMD' and click 'Authorize'"
}

function ih::setup::core.github::_check_sso_auth() {
  git ls-remote git@github.com:ConsultingMD/engineering.git &>/dev/null
  return $?
}

function ih::setup::core.github::install() {
  # make sure gh is installed
  command -v gh >/dev/null 2>&1 || brew install gh

  echo "You are about to walk through the gh CLI tool auth process.
Please choose:
 authenticate to github.com
 use SSH as preferred protocol
 upload your SSH key
 authenticate with a web browser
 "

  # gh auth login will use
  # the GITHUB_TOKEN env var if it is set
  # which will likely lack the scopes we need
  # as listed below.
  #
  # To avoid this problem,
  # we are unsetting it
  unset GITHUB_TOKEN

  # log in with scopes we need to update keys
  gh auth login --scopes repo,read:org,admin:public_key,user,admin:ssh_signing_key

  # now that we are authenticated,
  # we must ensure we've been added
  # to the @ConsultingMD/engineering team
  # otherwise, we can't access the repo
  # which verifies our SSO auth

  HAS_ENG_GITHUB_TEAM_ACCESS=$(gh api \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    /user/teams | jq -e 'any(.[]; .name == "Engineering")')

  if [[ $HAS_ENG_GITHUB_TEAM_ACCESS == "x" ]]; then
    ih::log::info "You are a member of the Engineering team in GitHub."
  else
    ih::log::warn "You are not a member of the Engineering team in GitHub."
    ih::log::info "Please reach out to #infrastructure-support on Slack to request access."
    return 1
  fi

  local PUBLIC_KEY
  local EXISTING_KEYS
  PUBLIC_KEY=$(cat "$HOME"/.ssh/id_rsa.pub)
  EXISTING_KEYS=$(gh ssh-key list)

  if [[ $EXISTING_KEYS =~ $PUBLIC_KEY ]]; then
    echo "Your SSH key has already been added to GitHub"
  else
    gh ssh-key add "$HOME/.ssh/id_rsa.pub" -t "Included Health"
  fi

  # Check basic GitHub authentication
  local SSH_RESULT
  SSH_RESULT=$(ssh git@github.com 2>&1)

  if [[ ! $SSH_RESULT =~ "You've successfully authenticated" ]]; then
    ih::log::error "Basic GitHub SSH authentication failed"
    ih::log::info "Try re-running the SSH setup step with: ih-setup install -f core ssh"
    ih::log::info "Then run this step again with: ih-setup install -f core github"
    return 1
  fi

  echo "Basic GitHub authentication successful"

  # Now handle SAML SSO authorization
  ih::log::warn "IMPORTANT: You must authorize your SSH key for the ConsultingMD organization"
  ih::setup::core.github::_show_sso_instructions

  ih::ask::enter-continue "Press enter to open the GitHub SSH keys page."
  open "https://github.com/settings/keys"

  ih::ask::enter-continue "After completing the steps above, press enter to verify your authorization."

  if ih::setup::core.github::_check_sso_auth; then
    ih::log::info "✅ Success! Your SSH key is now authorized for the ConsultingMD organization."
    echo "GitHub configuration complete"
    return 0
  else
    ih::log::error "❌ Your SSH key is not authorized for the ConsultingMD organization."
    ih::setup::core.github::_show_sso_instructions

    if ih::ask::confirm "Would you like to try again?"; then
      open "https://github.com/settings/keys"
      ih::ask::enter-continue "After completing the steps above, press enter to verify..."

      if ih::setup::core.github::_check_sso_auth; then
        ih::log::info "✅ Success! Your SSH key is now authorized for the ConsultingMD organization."
        echo "GitHub configuration complete"
        return 0
      else
        ih::log::error "❌ Authorization still failed. Please run 'ih-setup install -f core github' after completing the steps."
        return 1
      fi
    else
      ih::log::error "SAML SSO authorization is required to continue. Please run 'ih-setup install -f core github' after completing the steps."
      return 1
    fi
  fi
}
