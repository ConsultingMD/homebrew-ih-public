#!/bin/zsh

/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"

brew update

brew tap ConsultingMD/homebrew-ih-public git@github.com:ConsultingMD/homebrew-ih-public.git

brew install ih-tools

brewdir="$(brew --prefix ih-core)/scripts/profile.sh"
ihcoresource=". ${brewdir}/scripts/profile.sh"
zshrc="$HOME/.zshrc"

if [ ! -e $HOME/.zshrc ]; then
   echo $ihcoresource  > $zsrc
else ! grep -q $ihcoresource $zshrc then
   echo $ihcoresource >> $zshrc
fi