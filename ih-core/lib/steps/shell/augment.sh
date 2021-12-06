#!/bin/bash

# This script bootstraps the other Included Health shell scripts

# DO NOT EDIT THIS SCRIPT, IT MAY BE OVERWRITTEN BY FUTURE UPDATES

# To add additional behavior add a script to the $HOME/.ih/custom folder.
# Scripts in the $HOME/.ih/custom will be sourced in order.

IH_DIR=$HOME/.ih

for f in "$IH_DIR"/default/*; do
  # shellcheck source=/dev/null
  . "$f"
done

for f in "$IH_DIR"/custom/*; do
  # shellcheck source=/dev/null
  . "$f"
done
