#!/bin/bash
# Shebang indicates bash to enable shellcheck

# These are some default settings for zsh suggested
# by the Developer Platform team. You can override these in the
# zsh_custom.sh file.

# ██████╗  ██████╗     ███╗   ██╗ ██████╗ ████████╗    ███████╗██████╗ ██╗████████╗
# ██╔══██╗██╔═══██╗    ████╗  ██║██╔═══██╗╚══██╔══╝    ██╔════╝██╔══██╗██║╚══██╔══╝
# ██║  ██║██║   ██║    ██╔██╗ ██║██║   ██║   ██║       █████╗  ██║  ██║██║   ██║
# ██║  ██║██║   ██║    ██║╚██╗██║██║   ██║   ██║       ██╔══╝  ██║  ██║██║   ██║
# ██████╔╝╚██████╔╝    ██║ ╚████║╚██████╔╝   ██║       ███████╗██████╔╝██║   ██║
# ╚═════╝  ╚═════╝     ╚═╝  ╚═══╝ ╚═════╝    ╚═╝       ╚══════╝╚═════╝ ╚═╝   ╚═╝
# Changes to this file will be overwritten if you update the ih-core formula

# Only continue if we're on zsh
if [[ ! $(ps -cp "$$" -o command="") =~ "zsh" ]]; then
  return 0
fi

# show git branch in prompt
_parse_git_branch() {
  git branch 2>/dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
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

setopt PROMPT_SUBST

if [[ ${#PROMPT} -lt 10 ]]; then

  # Set prompt if they don't already have a non-trivial PROMPT

  #shellcheck disable=SC2016
  export PROMPT='%9c%{%F{green}%}$(_parse_git_branch)%{%F{none}%} $(_awsenv) $ '
fi

# Open SSL management
# https://github.com/rbenv/ruby-build/discussions/2185#discussioncomment-5588486
BREW_PREFIX_OPENSSL="$(brew --prefix openssl@3)"
export PATH="$BREW_PREFIX_OPENSSL/bin:$PATH"
export LDFLAGS="-L$BREW_PREFIX_OPENSSL/lib"
export CPPFLAGS="-I$BREW_PREFIX_OPENSSL/include"
export PKG_CONFIG_PATH="$BREW_PREFIX_OPENSSL/lib/pkgconfig"

# Rancher desktop added to the PATH
export PATH=$PATH:/Users/$USER/.rd/bin

# Refresh the path hashes since we changed it
rehash

export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

# Open .zshrc in an editor and then source it when you're done.
alias edit-zshrc='eval "$EDITOR $HOME/.zshrc" && source $HOME/.zshrc'
# Open your default zsh aliases file in an editor and then source it when you're done.
alias edit-aliases='eval "$EDITOR $HOME/.ih/custom/99_zsh.sh" && source $HOME/.ih/custom/99_zsh.sh'
alias edit-env='eval "$EDITOR $HOME/.ih/custom/00_env.sh" && source $HOME/.ih/custom/00_env.sh'

# Wire up completions for things installed by brew
if type brew &>/dev/null; then
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
fi

# compinit: do not run here — duplicates ~/.zshrc when compinit runs after augment.sh.
# In ~/.zshrc, after sourcing "$HOME/.ih/augment.sh", set fpath (plugins, etc.), then once:
#   autoload -Uz compinit && compinit -C -d "$ZSH_COMPDUMP"  # or compinit -d on first run

# ██████╗  ██████╗     ███╗   ██╗ ██████╗ ████████╗    ███████╗██████╗ ██╗████████╗
# ██╔══██╗██╔═══██╗    ████╗  ██║██╔═══██╗╚══██╔══╝    ██╔════╝██╔══██╗██║╚══██╔══╝
# ██║  ██║██║   ██║    ██╔██╗ ██║██║   ██║   ██║       █████╗  ██║  ██║██║   ██║
# ██║  ██║██║   ██║    ██║╚██╗██║██║   ██║   ██║       ██╔══╝  ██║  ██║██║   ██║
# ██████╔╝╚██████╔╝    ██║ ╚████║╚██████╔╝   ██║       ███████╗██████╔╝██║   ██║
# ╚═════╝  ╚═════╝     ╚═╝  ╚═══╝ ╚═════╝    ╚═╝       ╚══════╝╚═════╝ ╚═╝   ╚═╝
# Changes to this file will be overwritten if you update the ih-core formula
