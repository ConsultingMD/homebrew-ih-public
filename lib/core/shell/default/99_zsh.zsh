#!/bin/bash
# Shebang indicates bash to enable shellcheck.
# Body below is zsh-only (see guard). ShellCheck has no zsh dialect — use disables for zsh syntax, not "shell=zsh" (SC1103).

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
if [[ -z "${ZSH_VERSION:-}" ]]; then
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

# Fast Go asdf boot: brew binary + shims; no asdf.sh at startup
export ASDF_DATA_DIR="${ASDF_DATA_DIR:-$HOME/.asdf}"
if type brew &>/dev/null; then
	_ih_asdf_brew_prefix="$(brew --prefix asdf 2>/dev/null)"
	if [[ -n $_ih_asdf_brew_prefix && -x "${_ih_asdf_brew_prefix}/bin/asdf" ]]; then
		export PATH="${_ih_asdf_brew_prefix}/bin:$PATH"
	fi
fi
if [[ -d "$ASDF_DATA_DIR/shims" ]] && [[ ":$PATH:" != *":$ASDF_DATA_DIR/shims:"* ]]; then
	export PATH="$ASDF_DATA_DIR/shims:$PATH"
fi
if [[ -f "$ASDF_DATA_DIR/completions/_asdf" ]]; then
	FPATH="${ASDF_DATA_DIR}/completions:${FPATH}"
fi
unset _ih_asdf_brew_prefix

# Lazy asdf: full source_asdf + completions on first CLI use (Go asdf uses shims until then)
# shellcheck disable=SC2039,SC2206
if command -v asdf >/dev/null 2>&1; then
	asdf() {
		unfunction asdf 2>/dev/null
		((${+functions[source_asdf]})) && source_asdf
		if [[ -f "${ASDF_DATA_DIR}/completions/_asdf" ]] &&
			[[ ${fpath[(ie)$ASDF_DATA_DIR / completions]} -gt ${#fpath} ]]; then
			fpath=("${ASDF_DATA_DIR}/completions" $fpath)
			autoload -Uz compinit
			if [[ -n "${ZSH_COMPDUMP:-}" ]]; then
				if [[ -f "${ZSH_COMPDUMP}.zwc" ]]; then
					compinit -C -d "$ZSH_COMPDUMP"
				else
					compinit -d "$ZSH_COMPDUMP"
				fi
			else
				compinit -C
			fi
		fi
		command asdf "$@"
	}
fi

# compinit: NOT run here (duplicate + wrong fpath order).
# In ~/.zshrc, after "$HOME/.ih/augment.sh" and after final fpath setup:
#   1. Add plugin completions to fpath (e.g. fzf-tab) before compinit.
#   2. autoload -Uz compinit && compinit -C -d "$ZSH_COMPDUMP" (or compinit -d on first run).
#   3. Optional: autoload -Uz bashcompinit && bashcompinit (gcloud / Bash-style completions).
#   4. Then source plugins (zsh-syntax-highlighting, fzf-tab, etc.).
# Lazy asdf() above may call compinit again only if _asdf is created on first `asdf` use.

# ██████╗  ██████╗     ███╗   ██╗ ██████╗ ████████╗    ███████╗██████╗ ██╗████████╗
# ██╔══██╗██╔═══██╗    ████╗  ██║██╔═══██╗╚══██╔══╝    ██╔════╝██╔══██╗██║╚══██╔══╝
# ██║  ██║██║   ██║    ██╔██╗ ██║██║   ██║   ██║       █████╗  ██║  ██║██║   ██║
# ██║  ██║██║   ██║    ██║╚██╗██║██║   ██║   ██║       ██╔══╝  ██║  ██║██║   ██║
# ██████╔╝╚██████╔╝    ██║ ╚████║╚██████╔╝   ██║       ███████╗██████╔╝██║   ██║
# ╚═════╝  ╚═════╝     ╚═╝  ╚═══╝ ╚═════╝    ╚═╝       ╚══════╝╚═════╝ ╚═╝   ╚═╝
# Changes to this file will be overwritten if you update the ih-core formula
