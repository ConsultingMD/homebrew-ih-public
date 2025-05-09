# ⚠️ WARNING: This Repository is Public ⚠️

Please be aware that this repository is public, which means that anyone can view its contents (including sensitive information!).

## 🛑 STOP! 🛑

Before pushing changes, please double-check that you're not accidentally revealing any sensitive information.

# homebrew-ih-public

This repo contains the scripts and brew formulas used to onboard developers and
automate workflows.

## Onboarding

If you're here to onboard, start by running the command below in a terminal:
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/ConsultingMD/homebrew-ih-public/master/bootstrap)"
```

This will install Homebrew (if needed), tap this repo, install the `ih-setup` script, and kick off the
onboarding process. Follow the instructions in the script and you should be ready to go in no time.
You can also just manually run through the steps in the [bootstrap](./bootstrap) script.

If you run into problems with the script, let the Delivery team know in Slack [here](https://ih-epdd.slack.com/archives/C03GXCDA48Y).

You can run `ih-setup help` for help running the setup steps.

### What will the onboarding script (ih-setup) do to my machine?

The  script will start by creating an `.ih` folder in your `$HOME` and adding a line to `.zshrc` and `.bashrc`
to source the `.ih/augment.sh` file into your shell. This is the entry point for all IH modifications of your
shell; if you want to disable those modifications just remove that line.

`augment.sh` will source some additional files, first from `.ih/default` and then `.ih/custom`. The files in
`.ih/default` wire up various functions and tools which are needed in IH engineering workflows, and also
set some sane defaults for your shell. You shouldn't edit those files; they will be overwritten whenever
the ih-core formula is updated. The files in `.ih/custom` folder are initialized with some environment variables
but you can modify them to suit your needs. If you don't already have a pattern for organizing your shell
customizations consider using the `.ih/custom` folder as a place for them. In particular, if you don't like
the effects of the `.ih/default` scripts, `.ih/custom` is a good place to override them.

## Working in this repo

### How to release a new version

Before you submit a PR with your change, run `meta/bump`. This will print off the current version.
Then run `meta/bump {version you want}`. This will update the version everywhere it needs to be updated.
When your PR is merged, a new release with the new version will be created.

### Overview

The ih-setup script works by scanning the folders in ./lib for files which contain functions
which match the pattern `ih::setup::(\w*)::install`. These functions are considered to represent installers
for setup steps. The setup steps are expected to implement several functions following that pattern:

- `ih::setup::NAME::help` Describes what the step does
- `ih::setup::NAME::test` Tests whether the step is installed
- `ih::setup::NAME::deps` Returns a list of the other steps this step depends on
- `ih::setup::NAME::install` Installs the step

To add more steps use the script `./meta/add-step $FOLDER $NAME`.

The `ih-setup` script provides commands for installing the steps and checking if they are installed.
If you run `ih-setup install` it installs all the steps which are not yet installed.
If you run `ih-setup check` it will tell you which steps are installed.

### Structure
- [bin/](./bin) Contains the `ih-setup` script itself.
- [formula/](./formula) Contains the brew formula implemented in this repo.
- [lib/](./lib) Contains some shared libraries used by the steps, and the folders containing the setup
  steps.
    - [cds/](./lib/cds) A few setup scripts to help with joining the Core Data Services team. This is
      really just a proof-of-concept for per-team setup steps.
    - [core/](./lib/core) The core setup scripts used for standard onboarding.
    - [utils/](./lib/utils) Utility functions which can be used in the steps.

- [meta/](./meta) Contains scripts and tools for managing working on this repo itself.
  This will be refactored to be the template for how we want to standardize repo init/build/test commands.
    - [add-step](./meta/add-step) Add a new setup step; use `./meta/add-step {folder} {name}`
    - [bump](./meta/bump) Bumps the version of the formula. If called with no arg it shows the current version.
    - [test](./meta/test) Spawn a new shell with the current ih-setup from this repo in the path.
       This can be destructive, so be careful!
    - [test-isolated](./meta/test-setup) Spawn a new shell in a temporary directory where you can test the install script with $HOME set to the temp directory. Use `./meta/test-setup reset` to delete the directory and recreate it.
    - [release](./meta/release) Create a new release of the formula. Must be run on the main branch with a clean repo.
- [bootstrap](./bootstrap) is the script that kicks off bootstrapping.

### Brew
The brew formula just points to the release bundle in github. It downloads the release bundle (which contains
all the code in this repo) and copies the `./bin` and `./lib` directories into the brew location,
and links ih-setup into /usr/local/bin.

### Testing

To invoke the setup script,
run `./bin/ih-setup` in a terminal.

To test out the setup script without affecting your actual setup, run the script
at `./meta/test-isolated`. It will create a fake home directory where you can
experiment with the `ih-setup` command. Run `./meta/test-isolated reset` to
purge the fake directory and create a new one.

You can test the setup script against your actual $HOME by running `./meta/test zsh`
or `./meta/test bash`. This will start a new shell of the specified type without loading
your existing .\*rc files. Be careful, as running steps in this mode will update your
real $HOME directory with things.
