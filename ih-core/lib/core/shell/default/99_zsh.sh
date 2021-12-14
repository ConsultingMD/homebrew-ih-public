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
SHELL=$(ps -cp "$$" -o command="")
if [[ ! $SHELL =~ "zsh" ]]; then
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
#shellcheck disable=SC2016
export PROMPT='%9c%{%F{green}%}$(_parse_git_branch)%{%F{none}%} $(_awsenv) $ '

# Open SSL management
export PATH="/usr/local/opt/openssl@1.1/bin:$PATH"
export LDFLAGS="-L/usr/local/opt/openssl@1.1/lib"
export CPPFLAGS="-I/usr/local/opt/openssl@1.1/include"
export PKG_CONFIG_PATH="/usr/local/opt/openssl@1.1/lib/pkgconfig"

# Refresh the path hashes since we changed it
rehash

export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced

# Open .zshrc in an editor and then source it when you're done.
alias edit-zshrc="\$EDITOR \$HOME/.zshrc && source \$HOME/.zshrc"
# Open your default zsh aliases file in an editor and then source it when you're done.
alias edit-aliases="\$EDITOR \$HOME/.ih/custom/99_zsh.sh && source \$HOME/.ih/custom/99_zsh.sh"
alias edit-env="\$EDITOR \$HOME/.ih/custom/00_env.sh && source \$HOME/.ih/custom/00_env.sh"

# Wire up completions for things installed by brew
if type brew &>/dev/null; then
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
fi

autoload -Uz compinit
compinit

# ██████╗  ██████╗     ███╗   ██╗ ██████╗ ████████╗    ███████╗██████╗ ██╗████████╗
# ██╔══██╗██╔═══██╗    ████╗  ██║██╔═══██╗╚══██╔══╝    ██╔════╝██╔══██╗██║╚══██╔══╝
# ██║  ██║██║   ██║    ██╔██╗ ██║██║   ██║   ██║       █████╗  ██║  ██║██║   ██║
# ██║  ██║██║   ██║    ██║╚██╗██║██║   ██║   ██║       ██╔══╝  ██║  ██║██║   ██║
# ██████╔╝╚██████╔╝    ██║ ╚████║╚██████╔╝   ██║       ███████╗██████╔╝██║   ██║
# ╚═════╝  ╚═════╝     ╚═╝  ╚═══╝ ╚═════╝    ╚═╝       ╚══════╝╚═════╝ ╚═╝   ╚═╝
# Changes to this file will be overwritten if you update the ih-core formula