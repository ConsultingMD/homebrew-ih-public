#!/bin/bash
# disable check for using variable in printf
# disable mapfile warnings for arrays since it does not work on mac
# shellcheck disable=2059
# shellcheck disable=2207
# shellcheck disable=2155

# Override getopt location because we will have installed it using brew.
GETOPT_LOCATION=/usr/local/opt/gnu-getopt/bin/getopt

function gr::echo_out() {
  # If this is outputting to an eval statement we need to output a "echo" as well
  local color nc format
  case "$1" in
    ERROR)
      color=$(tput setaf 1)
    ;;
    WARN)
      color=$(tput setaf 3)
    ;;
    INFO)
      color=$(tput setaf 2)
    ;;
    *)
      # Severity is a quasi-required argument.  But since this is used to
      # output errors, just use an obnoxious default to communicate that.
      color=$(tput setaf 5)
      set -- 'WACK' "$@"
    ;;
  esac
  nc=$(tput sgr0)
  format="[${color}%5s${nc}]:\\t%s\\n"

  if [ -z "$OUTPUT_TO_EVAL" ] || [ "$0" = "$BASH_SOURCE" ]; then
    printf "${format}" "${1}" "${*:2}" 1>&2
  else
    echo "echo \"$*\";" 1>&2
  fi
}

gr::aws_environment::ignored_option() {
  echo "Ignoring removed option: '$1'" > /dev/stderr
}

# shellcheck disable=1091
# shellcheck disable=2086
function gr::aws_environment::main() {

  #######
  # PRE-CONDITIONS
  #######
  # require jq
  if ! command -v jq > /dev/null 2>&1; then
    gr::echo_out "ERROR" "aws-environment requires 'jq' to be installed"
    return 1
  fi
  # require aws cli
  if ! command -v aws > /dev/null 2>&1; then
    gr::echo_out "ERROR" "aws-environment requires 'aws' to be installed"
    return 1
  fi

  if [ -z "${GETOPT_LOCATION}" ]; then
    gr::aws_environment::getopt_location
  fi

  if [ ! -d "${HOME}/.aws" ]; then
    mkdir ~/.aws
  fi

  if [ -z "$1" ]; then
    echo "${AWS_ENVIRONMENT:-Environment not set. Provide an argument to set it}"
    [[ -z $AWS_ENVIRONMENT ]] && return 1 || return 0
  fi

  #######
  # OPT_PARSING
  #######
  local argument_options role help_message region refresh_credentials
  argument_options=$($GETOPT_LOCATION -o hlr: -l help,init,legacy,refresh,region:,list-access,sso,no-sso -n 'aws-environment' -- "$@")
  eval set -- "$argument_options"
  while true; do
    case "$1" in
      -h | --help ) help_message=true; shift ;;
      --region ) region="$2"; shift 2 ;;
      --init ) gr::aws_environment::init; shift ; return;;
      --refresh ) refresh_credentials=true; shift ;;
      --list-access ) gr::aws_environment::list_access; shift ; return ;;
      --sso|--no-sso|-l|--legacy) gr::aws_environment::ignored_option "$1"; shift ;;
      --) shift ; break ;;
      * ) break ;;
    esac
  done
  #######
  # HELP TEXT
  #######
  if [[ ! -z $help_message ]]; then
    local format
    format="    %-18s\\t%10s\\n"
    echo "function-name - aws role assumption: "
    echo "Usage: function-name [arguments] ENVIRONMENT"
    echo "Arguments:"
    printf "$format" "-h,--help" "Print out this help information."
    printf "$format" "--region [region]" "region, default:us-east-1."
    printf "$format" "--init" "Initialize the accounts file mapping names to account ids."
    printf "$format" "--refresh" "Refreshes your account session."
    printf "$format" "--list-access" "List roles and accounts that you currently have access to."
    return 0
  fi

  aws-sso-setup check
  local _status=$?

  if [ "$_status" -eq 2 ]; then
    aws-sso-setup generate || return 1
  elif [ "$_status" -ne 0 ]; then
    return 1
  fi

  account_name=$1
  role=$2
  region=${region:-"us-east-1"}
  export AWS_DEFAULT_REGION="${region}"

  if [ "${region}" = "us-east-1" ]; then
    export S3_BUCKET_PREFIX="grnds-${account_name}-"
  else
    export S3_BUCKET_PREFIX="grnds-${account_name}-${region}-"
  fi

  roles=( $(aws-sso-setup show | awk '$1 == "'"$account_name"'" {print $2}') )

  if [ ! "$role" ]; then
    if [ "$AWS_DEFAULT_ROLE" ]; then
      role="$AWS_DEFAULT_ROLE"
    elif [ ${#roles[@]} -eq 1 ]; then
      role="${roles[0]}"
    else
      gr::echo_out "WARN" "Specify a role name, valid roles are: ${roles[@]}"
      gr::echo_out "WARN" "You can request new role(s) from IT Support: https://helpcenter.grandrounds.com"
      return 1
    fi
  fi

  if [[ ! " ${roles[@]} " =~ " ${role} " ]]; then
    gr::echo_out "WARN" "Invalid role ('$role') or account ('$account_name')"
    gr::echo_out "WARN" "Specify a role name, valid roles for account '$account_name' are: ${roles[@]}"
    gr::echo_out "WARN" "You can request new role(s) from IT Support: https://helpcenter.grandrounds.com"
    return 1
  fi

  gr::aws_environment::clean_env

  export AWS_PROFILE="$account_name-$role-$region"
  export AWS_ENVIRONMENT="$account_name"
  export AWS_ENVIRONMENT_ROLE="$role"
  if [ "$refresh_credentials" ]; then
    aws-sso-setup refresh
  fi

  # Always get traditional creds to interop with older tools/code that don't
  # yet support AWS SSO.
  local creds
  creds=$(mktemp)
  aws-sso-setup credentials > "$creds"
  source "$creds"
  rm "$creds"

  gr::aws_environment::vault_env

  if ! gr-ecr-login > /dev/null 2>&1; then
    gr::echo_out "WARN" "Could not login to ECR. This can be ignored unless you are developer working with docker."
  fi

  return 0
}

#######################################
# gr::aws_environment::getopt_location
# Description:
#   tests various getopt versions to make sure they are correct
#   then exports GETOPT_LOCATION for ease of use
# Globals:
# Arguments:
# Returns:
#   location of a gnu compatible getopt
#######################################
# shellcheck disable=2230
# shellcheck disable=2046
function gr::aws_environment::getopt_location() {
  getopt_locations=( $(which -a getopt) )
  if [ $(command -v brew) ]; then
    getopt_locations+=("$(brew --prefix gnu-getopt)/bin/getopt")
  fi
  for getopt in ${getopt_locations[*]}; do
    getopt_out=$(${getopt} -T)
    if (( $? != 4 )) && [[ -n $getopt_out ]]; then
      gr::echo_out "WARN" "Bad getopt at $getopt, returned $getopt_out with code $?"
      continue
    else
      export GETOPT_LOCATION="${getopt}"
      return
    fi
  done
  gr::echo_out "ERROR" "Unable to find GNU compatible getopt"
  return 1
}

function gr::aws_environment::init() {
  aws-sso-setup generate
}

function gr::aws_environment::list_access() {
  aws-sso-setup show
}

function gr::aws_environment::vault_env(){
  case "${AWS_ENVIRONMENT:?}" in
    integration3|uat|production)
      export VAULT_ADDR=https://vault.$AWS_ENVIRONMENT.grnds.com
      ;;
    *)
      unset VAULT_ADDR
      ;;
  esac
}

function gr::aws_environment::clean_env() {
  local reset_session=${1:-0}
  unset AWS_ENVIRONMENT_ROLE
  unset AWS_PROFILE
  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_SECRET_KEY
  unset AWS_SESSION_TOKEN
  unset AWS_SESSION_START
  if [ "${reset_session}" -ne 0 ]; then
    unset AWS_SESSION_ACCESS_KEY_ID
    unset AWS_SESSION_SECRET_ACCESS_KEY
    unset AWS_SESSION_SESSION_TOKEN
  fi
}

function aws-environment() {
  gr::aws_environment::main "$@"
}

alias gr-aws-environment=aws-environment
alias gr-env=aws-environment

function assume-role() {
  local role identity session_name account_id creds

  role="${1:?}"

  identity=$(aws sts get-caller-identity)
  session_name=$(jq -j .Arn <<< "$identity" | awk -F/ '{print $NF}')
  account_id=$(jq -j .Account <<< "$identity")

  creds=$(aws sts assume-role --role-arn "arn:aws:iam::$account_id:role/$role" --role-session-name "$session_name")
  export AWS_ACCESS_KEY_ID=$(jq -j .Credentials.AccessKeyId <<< "$creds")
  export AWS_SECRET_ACCESS_KEY=$(jq -j .Credentials.SecretAccessKey <<< "$creds")
  export AWS_SESSION_TOKEN=$(jq -j .Credentials.SessionToken <<< "$creds")
}

function gr::aws_environment::completer() {
  local cur prev firstword lastword complete_words accounts account_reg roles
  if [ -n "$BASH_VERSION" ]; then
    shopt -s extglob
  fi
  COMP_WORDBREAKS=${COMP_WORDBREAKS//[:=]}
  cur=${COMP_WORDS[COMP_CWORD]}
  prev=${COMP_WORDS[COMP_CWORD-1]}
  firstword=$(gr::aws_environment::firstword)
  lastword=$(gr::aws_environment::lastword)

  if [[ -f ~/.aws/access.db ]]; then
    opts="--list-access --help --init"
    opts_reg="+(${opts// /|})"

    accounts=( $(cut -d' ' -f2 ~/.aws/access.db | tr 'A-Z' 'a-z' | sort -u) )
    account_reg="+($(IFS='|' ; echo "${accounts[*]}"))"

    roles=( $(cut -d' ' -f3 ~/.aws/access.db | tr 'A-Z' 'a-z' | sort -u) )
    roles_reg="+($(IFS='|' ; echo "${roles[*]}"))"
  else
    opts="--help --init"
  fi
  case "${firstword}" in
    *)
      case "${prev}" in
        aws-environment)
          complete_words="${accounts[*]} ${opts}";
        ;;
        $opts_reg)
          end=true
        ;;
        $account_reg)
          complete_words="${roles[*]} --refresh --region"
          end=true
        ;;
        $roles_reg)
          complete_words="--refresh --region"
          end=true
        ;;
        --region)
          complete_words="us-east-1 us-west-2"
          end=true
        ;;
        *)
          if [ ! ${end} ]; then
            gr::echo_out "WARN" "Unknown Option or Environment"
          fi
        ;;
      esac
  esac
  COMPREPLY=( $( compgen -W "$complete_words" -- "$cur" ))
  return 0
}

function gr::aws_environment::firstword() {
  local firstword i
  firstword=
  for ((i = 1; i < ${#COMP_WORDS[@]}; ++i)); do
    if [[ ${COMP_WORDS[i]} != -* ]]; then
      firstword=${COMP_WORDS[i]}
      break
    fi
  done
  echo "$firstword"
}

function gr::aws_environment::lastword() {
  local lastword i
  lastword=
  for ((i = 1; i < ${#COMP_WORDS[@]}; ++i)); do
    if [[ ${COMP_WORDS[i]} != "-*" ]] && [[ -n ${COMP_WORDS[i]} ]] && [[ ${COMP_WORDS[i]} != "$cur" ]]; then
      lastword=${COMP_WORDS[i]}
    fi
  done
  echo "$lastword"
}

if command -v complete > /dev/null 2>&1; then
  complete -F gr::aws_environment::completer aws-environment
fi

# Not meaningful now that we've switched to AWS SSO. Setting for compatibility.
export AWS_USERNAME="$USER"
