# ih-core

This folder contains the core setup scripts, starting at bootstrap.sh.

[bootstrap.sh](./bootstrap.sh) is the script that kicks off bootstrapping.
You can invoke it using `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/ConsultingMD/homebrew-ih-public/master/ih-core/bootstrap)"`

You can also install the components using brew:

```
brew tap ConsultingMD/homebrew-ih-public git@github.com:ConsultingMD/homebrew-ih-public.git
brew install ih-core
```

Once you've installed the ih-core components using brew you can run `ih-setup install` to begin onboarding.

## Folders

- [./bin](./bin) Contains the scripts scripts and tools for managing working on this repo itself.
- [./lib](./lib) Contains some shared libraries used by the steps, and the folders containing the setup
  steps themselves. The setup steps can't be executed directly, they are discovered by the ih-setup script.


## Overview

The ih-setup script works by scanning the folders in ./lib/steps for files which contain functions
which match the pattern `ih::setup::(\w*)::install`. These functions are considered to represent installers
for setup steps. The setup steps are expected to implement several functions following that pattern:

- `ih::setup::NAME::help` Describes what the step does
- `ih::setup::NAME::test` Tests whether the step is installed
- `ih::setup::NAME::deps` Returns a list of the other steps this step depends on
- `ih::setup::NAME::install` Installs the step

To add more steps use the script `./meta/add-step $NAME`.

The `ih-setup` script provides commands for installing the steps and checking if they are installed.
If you run `ih-setup install` it installs all the steps which are not yet installed.
If you run `ih-setup check` it will tell you which steps are installed.
