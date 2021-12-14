# homebrew-ih-public

This repo contains the scripts and brew formulas used to onboard developers and
automate workflows.

## Folders

- [./meta](./meta) Contains scripts and tools for managing working on this repo itself.
  This will be refactored to be the template for how we want to standardize repo init/build/test commands.
    - [add-step](./meta/add-step) Add a new setup step; use `./meta/add-step {folder} {name}`
    - [test-setup](./meta/test-setup) Spawn a new shell in a temporary directory where you can test the install script with $HOME set to the temp directory. Use `./meta/test-setup reset` to delete the directory and recreate it.
    - [release](./meta/release) Create a new release of the formula. Must be run on the main branch with a clean repo. Use `./meta/release x.y.z` to create the release.
- [./ih-core](./ih-core) Contains the core tools used by all teams, and the bootstrapping scripts for initial onboarding/setup.
  See the readme in this folder for details on how to install the ih-core components.
- [./formula](./formula) Contains the brew formula implemented in this repo.

## Brew
The brew formula just points to the release bundle in github. It downloads the release bundle (which contains
all the code in this repo) and copies the ih-core/bin and ih-core/lib directories into the brew location,
and links ih-setup into /usr/local/bin.

Note that the brew formula will eventually depend on a bunch of other tools we want to
automatically install, but right now it doesn't (this makes testing easier).

Note that we are also not yet installing or wiring up asdf plugins.

Note that we are not currently setting up the AWS environment stuff.

## Testing

To test out the setup script without affecting your actual setup, run the script
at `./meta/test-setup`. It will create a fake home directory where you can
experiment with the `ih-setup` command. Run `./meta/test-setup reset` to
purge the fake directory and create a new one.
