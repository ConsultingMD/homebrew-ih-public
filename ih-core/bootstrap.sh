#!/bin/bash

if ! command -v brew &> /dev/null; then
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
fi

brew update

brew tap ConsultingMD/homebrew-ih-public git@github.com:ConsultingMD/homebrew-ih-public.git

brew install ih-core

ih-setup install

echo "If install succeeded, remember to source your .zshrc or .bashrc now that setup is complete, or start a new shell."