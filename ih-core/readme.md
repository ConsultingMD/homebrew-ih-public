# ih-core 

This folder contains the core setup scripts, starting at bootstrap.sh.

[bootstrap.sh](./bootstrap.sh) is the script that kicks off bootstrapping.
You can invoke it using `/bin/bash -c "$(curl -fsSL https://github.com/ConsultingMD/homebrew-ih-public/archive/refs/latest/ih-core/bootstrap.sh)"`

You can also install the components using brew:

```
brew tap ConsultingMD/homebrew-ih-public git@github.com:ConsultingMD/homebrew-ih-public.git
brew install ih-core
```

Once you've install the ih-core components using brew you can run `ih-setup install` to begin onboarding.


### Folders

- [./bin](./bin) Contains the scripts scripts and tools for managing working on this repo itself. 
- [./lib](./lib) Contains some shared libraries used by the steps, and the folders containing the setup
  steps themselves. The setup steps can't be executed directly, they are discovered by the ih-setup script.