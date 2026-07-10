#!/bin/bash

# IH_CORE_DIR will be set to the directory containing the bin and lib directories.

function ih::setup::core.jira::help() {
  echo 'Configure JIRA API token for story automation and JSM on-call tools

    This step will:
        - Help you create an (unscoped) Atlassian API token
        - Validate it against both the Jira and JSM on-call (ops) APIs
        - Store the token in your keychain for use by JIRA CLI tools
    '
}

# Check if the step has been installed and return 0 if it has.
# Otherwise return 1.
function ih::setup::core.jira::test() {
  local JIRA_FILE="$HOME/.ih/default/09_jira.sh"

  if [[ ! -f "$JIRA_FILE" ]]; then
    ih::log::debug "JIRA augment file not found at $JIRA_FILE"
    return 1
  fi

  # The augment file existing isn't enough - the token itself must be in the
  # keychain. Without this check the step reports "installed" even when the
  # token is missing, and `install` (without -f) becomes a confusing no-op.
  if ! security find-generic-password -s "jira-api" >/dev/null 2>&1; then
    ih::log::debug "JIRA API token not found in keychain"
    return 1
  fi
}

function ih::setup::core.jira::deps() {
  echo "core.shell"
}

# Validates an API token against the APIs our tooling actually uses.
# Returns:
#   0 - token works for Jira and JSM ops (or ops check was inconclusive/forbidden)
#   1 - token is not valid for Jira at all (bad token / wrong username)
#   3 - token works for Jira but JSM ops rejects the credentials (401 - a scoped token)
function ih::setup::core.jira::validate-token() {
  local token="$1"
  local site="$2"
  local code

  # 1. Basic validity against the standard Jira REST API.
  code=$(curl -s -o /dev/null -w '%{http_code}' \
    -u "${JIRA_USERNAME}:${token}" \
    -H "Accept: application/json" \
    "https://${site}/rest/api/3/myself")
  if [[ "$code" != "200" ]]; then
    ih::log::error "Jira rejected the token (HTTP $code from /rest/api/3/myself).
Check that the token is correct and that JIRA_USERNAME (${JIRA_USERNAME}) is your Atlassian login email."
    return 1
  fi

  # 2. JSM on-call (ops) access. This requires an UNSCOPED (full-access) token;
  #    a token created "with scopes" cannot reach the ops config endpoints.
  local cloud_id
  cloud_id=$(curl -s "https://${site}/_edge/tenant_info" | sed -n 's/.*"cloudId":"\([^"]*\)".*/\1/p')
  if [[ -z "$cloud_id" ]]; then
    ih::log::warn "Could not resolve cloudId from ${site}; skipping the JSM ops check."
    return 0
  fi

  code=$(curl -s -o /dev/null -w '%{http_code}' \
    -u "${JIRA_USERNAME}:${token}" \
    -H "Accept: application/json" \
    "https://api.atlassian.com/jsm/ops/api/${cloud_id}/v1/notification-rules")

  case "$code" in
    200)
      ih::log::info "Token validated against both the Jira and JSM on-call APIs."
      return 0
      ;;
    401)
      # Credentials rejected outright. For an unscoped token that authenticates
      # fine against Jira above, this almost always means it was created WITH
      # scopes (scoped tokens can't reach the ops gateway).
      ih::log::error "This token works for Jira but the JSM on-call API rejected it (HTTP 401).
This almost always means it was created WITH scopes. On-call tooling needs a
full-access token. Please recreate it using \"Create API token\" (WITHOUT scopes) at:
  https://id.atlassian.com/manage/api-tokens"
      return 3
      ;;
    403 | 404)
      # Credentials were accepted; you're just not on an on-call team/schedule
      # yet. That's fine for setup - jsm-notify-setup surfaces team membership
      # when you actually run it. (Matches jsm-notify-setup, which treats 403 as
      # a valid token, not a credential error.)
      ih::log::info "Token accepted by the JSM on-call API (you may not be on an on-call team yet)."
      return 0
      ;;
    *)
      ih::log::warn "JSM ops check returned HTTP $code; continuing without blocking setup."
      return 0
      ;;
  esac
}

# Why we require an UNSCOPED token (not least-privilege, deliberately):
# this one keychain token is shared by make-branch/tng (which authenticate against
# the site URL https://includedhealth.atlassian.net) and jsm-notify-setup (which
# uses the api.atlassian.com ops gateway). Scoped tokens are SILENTLY IGNORED on
# site URLs, so a scoped token quietly breaks story automation. To move to minimal
# scopes we'd first have to migrate the site-URL callers to the api.atlassian.com/
# ex/jira/{cloudId} gateway; until then, unscoped is the only token that works
# everywhere. See platform-api/pkg/jira (JiraURL) and engineering/tracker-scripts.
function ih::setup::core.jira::install() {
  # Only name a keychain when TEST_KEYCHAIN is set (tests use a throwaway one).
  # Otherwise pass NO keychain arg so `security` uses the login/default keychain.
  # A literal "default" is not the default keychain - `security` treats it as a
  # keychain file name, misses the real item, and the add then collides against
  # login.keychain-db with errSecDuplicateItem.
  local -a KEYCHAIN_ARG=()
  if [[ -n "$TEST_KEYCHAIN" ]]; then
    KEYCHAIN_ARG=("$TEST_KEYCHAIN")
  fi
  local JIRA_SITE="includedhealth.atlassian.net"

  ih::ask::confirm "You will need to log in to JIRA and create an API token.
Your JIRA login is $JIRA_USERNAME.

When you press Y I will open a browser to https://id.atlassian.com/manage/api-tokens.

IMPORTANT: choose 'Create API token' WITHOUT scopes (full access). Do NOT use
'Create API token with scopes' - a scoped token cannot manage your JSM on-call
alert settings and may not permit story automation either.

Give it a label like 'jira-cli' and copy the token to your clipboard.
If you don't want to do this now, press n.
" || return 1

  open "https://id.atlassian.com/manage/api-tokens"

  local TOKEN
  read -r -s -p "Paste token here: " TOKEN
  echo ""

  # Every Atlassian API token (scoped or unscoped) starts with ATATT. A wrong
  # paste is usually a Bitbucket app password (ATBB), an access token (ATCTT),
  # or truncated. The prefix can't tell scoped from unscoped - only the
  # functional check below can - so this is just a fast sanity guard.
  if [[ "$TOKEN" != ATATT* ]]; then
    ih::log::warn "That doesn't look like an Atlassian API token (they start with 'ATATT')."
    ih::ask::retry-cancel "Paste it again?" || return 2
    ih::setup::core.jira::install
    return $?
  fi

  # Validate before storing so we never persist a token that can't do the job.
  ih::setup::core.jira::validate-token "$TOKEN" "$JIRA_SITE"
  local VALID=$?
  if [[ $VALID -eq 1 ]]; then
    ih::ask::retry-cancel "The token isn't valid for Jira. Recreate it?" || return 2
    ih::setup::core.jira::install
    return $?
  elif [[ $VALID -eq 3 ]]; then
    if ih::ask::retry-cancel "Recreate the token WITHOUT scopes now? (Cancel keeps this token.)"; then
      ih::setup::core.jira::install
      return $?
    fi
    ih::log::warn "Keeping a token that can't manage JSM on-call settings. Story automation may still work."
  fi

  # The `security` CLI can't reliably update a generic-password item in place:
  # even with -U it often returns errSecDuplicateItem (-25299, "item already
  # exists") when the service/account already exist. The portable idiom is
  # delete-then-add. We delete by service (we own "jira-api") to also clear a
  # stale entry stored under a different account, and ignore "not found" so a
  # first-time install still works.
  security delete-generic-password -s "jira-api" "${KEYCHAIN_ARG[@]}" >/dev/null 2>&1
  if ! security add-generic-password -a "$JIRA_USERNAME" -s "jira-api" -w "$TOKEN" -j "API Token for JIRA" "${KEYCHAIN_ARG[@]}"; then
    ih::log::error "Failed to store the token in the keychain."
    return 1
  fi

  cp -f "$IH_CORE_LIB_DIR/core/jira/default/09_jira.sh" "$IH_DEFAULT_DIR/09_jira.sh"
  ih::log::info "JIRA API token stored."
}
