#!/bin/bash

# These are some default settings for bash suggested
# by the Developer Platform team. You can override these in the
# bash_custom.sh file.

# ██████╗  ██████╗     ███╗   ██╗ ██████╗ ████████╗    ███████╗██████╗ ██╗████████╗
# ██╔══██╗██╔═══██╗    ████╗  ██║██╔═══██╗╚══██╔══╝    ██╔════╝██╔══██╗██║╚══██╔══╝
# ██║  ██║██║   ██║    ██╔██╗ ██║██║   ██║   ██║       █████╗  ██║  ██║██║   ██║
# ██║  ██║██║   ██║    ██║╚██╗██║██║   ██║   ██║       ██╔══╝  ██║  ██║██║   ██║
# ██████╔╝╚██████╔╝    ██║ ╚████║╚██████╔╝   ██║       ███████╗██████╔╝██║   ██║
# ╚═════╝  ╚═════╝     ╚═╝  ╚═══╝ ╚═════╝    ╚═╝       ╚══════╝╚═════╝ ╚═╝   ╚═╝
# Changes will be overwritten if you update the ih-core formula

# Only continue if we're on bash
if [[ ! $(ps -cp "$$" -o command="") =~ "bash" ]]; then
  return 0
fi

##########################################################
## Grand Rounds Bootstrap Config ##

# show git branch in prompt (with color)

function _parse_git_branch() {
  git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

RED="\033[0;31m"
YELLOW="\033[0;33m"
GREEN="\033[0;32m"
NO_COLOR="\033[0m"

function _git_color {
  local git_status
  git_status="$(git status 2>/dev/null)"

  if [[ $git_status =~ "working tree clean" ]]; then
    echo -e "$GREEN"
  elif [[ $git_status =~ "Your branch is ahead of" ]]; then
    echo -e "$YELLOW"
  elif [[ $git_status =~ "nothing added to commit but untracked" ]]; then
    echo -e "$YELLOW"
  elif [[ $git_status =~ "Changes to be committed" ]]; then
    echo -e "$YELLOW"
  elif [[ $git_status =~ "Changes not staged for commit" ]]; then
    echo -e "$RED"
  else
    echo -e "$NO_COLOR"
  fi
}

_awscolor() {
  case "$AWS_ENVIRONMENT" in
    production) echo -e "$RED" ;;
    uat) echo -e "$YELLOW" ;;
    *) echo -e "$GREEN" ;;
  esac
}

_awsenv() {
  if [ -n "$AWS_ENVIRONMENT" ]; then
    echo "🔧$AWS_ENVIRONMENT"
  elif [ -n "$AWS_ACCESS_KEY_ID" ]; then
    echo "🔧ops"
  else
    echo ""
  fi
}

if [[ "$PS1" = "\\s-\\v\\\$ " ]]; then
  # Set prompt if they don't already have a non-trivial PS1

  # Set command prompt to include branch names & Status when in a git folder
  PS1="\[\$(_git_color)\]\$(_parse_git_branch)\[$NO_COLOR\]\[\$(_awscolor)\]\$(_awsenv)\[$NO_COLOR\] \w\$ "
fi

# Open SSL management
export PATH="/usr/local/opt/openssl@1.1/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/openssl@1.1/lib"
export CPPFLAGS="-I/usr/local/opt/openssl@1.1/include"
export PKG_CONFIG_PATH="/usr/local/opt/openssl@1.1/lib/pkgconfig"
##########################################################

# Rancher desktop added to the PATH
export PATH=$PATH:/Users/$USER/.rd/bin


#Determine where a shell function is defined / declared
function find_function {
  shopt -s extdebug
  declare -F "\$1"
  shopt -u extdebug
}

# Open .bashrc in an editor and then source it when you're done.
alias edit-bashrc='$EDITOR $HOME/.bashrc && source $HOME/.bashrc'
# Open your default bash aliases file in an editor and then source it when you're done.
alias edit-aliases='$EDITOR $HOME/.ih.d/custom/bash.sh && source $HOME/.ih.d/custom/bash.sh'
alias edit-env='$EDITOR $HOME/.ih/custom/00_env.sh && source $HOME/.ih/custom/00_env.sh'

# Wire up completions for things installed using brew
if type brew &>/dev/null; then
  HOMEBREW_PREFIX="$(brew --prefix)"
  if [[ -r "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh" ]]; then

    # We're checking whether it exists above
    # shellcheck disable=SC1091
    source "${HOMEBREW_PREFIX}/etc/profile.d/bash_completion.sh"
  else
    for COMPLETION in "${HOMEBREW_PREFIX}/etc/bash_completion.d/"*; do
      # shellcheck disable=SC1090
      [[ -r "${COMPLETION}" ]] && source "${COMPLETION}"
    done
  fi
fi

# ██████╗  ██████╗     ███╗   ██╗ ██████╗ ████████╗    ███████╗██████╗ ██╗████████╗
# ██╔══██╗██╔═══██╗    ████╗  ██║██╔═══██╗╚══██╔══╝    ██╔════╝██╔══██╗██║╚══██╔══╝
# ██║  ██║██║   ██║    ██╔██╗ ██║██║   ██║   ██║       █████╗  ██║  ██║██║   ██║
# ██║  ██║██║   ██║    ██║╚██╗██║██║   ██║   ██║       ██╔══╝  ██║  ██║██║   ██║
# ██████╔╝╚██████╔╝    ██║ ╚████║╚██████╔╝   ██║       ███████╗██████╔╝██║   ██║
# ╚═════╝  ╚═════╝     ╚═╝  ╚═══╝ ╚═════╝    ╚═╝       ╚══════╝╚═════╝ ╚═╝   ╚═╝
# Changes will be overwritten if you update the ih-core formula
# Instead, update the corresponding file in ../custom, which will be sourced after this.
