#!/bin/bash

# This script bootstraps the other Included Health shell scripts

# DO NOT EDIT THIS SCRIPT, IT MAY BE OVERWRITTEN BY FUTURE UPDATES

# To add additional behavior add a script to the $HOME/.ih/custom folder.
# Scripts in the $HOME/.ih/custom will be sourced in order.

# shellcheck disable=SC1091

IH_DIR=$HOME/.ih

# Source custom environment so the variables are available
# in the default files, which may need them.
. "$IH_DIR/custom/00_env.sh"

for f in "$IH_DIR"/default/*; do
  # shellcheck source=/dev/null
  if grep -q "#!/" "$f"; then
    . "$f"
  fi
done

for f in "$IH_DIR"/custom/*; do
  # shellcheck source=/dev/null
  if grep -q "#!/" "$f"; then
    . "$f"
  fi
done
