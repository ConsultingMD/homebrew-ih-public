# homebrew-ih-public

This repo contains the scripts and brew formulas used to onboard developers and 
automate workflows. 

## Folders

- [./meta](./meta) Contains scripts and tools for managing working on this repo itself. 
  This will be refactored to be the template for how we want to standardize repo init/build/test commands.
- [./ih-core](./ih-core) Contains the core tools used by all teams, and the bootstrapping scripts for initial onboarding/setup.
- [./formula](./formula) Contains the brew formula implemented in this repo.

## Brew
The brew formula just points to the release bundle in github. It downloads the release bundle (which contains
all the code in this repo) and copies the ih-core/bin and ih-core/lib directories into the brew location,
and links ih-setup into /usr/local/bin.