#!/bin/bash

# Sources the IH augment shell script
# This has a dependency on what exactly the ./steps/shell/step.sh
# step does, so this function is here to
# avoid everything other step can have a single
# function to call if it wants to make sure the variables
# created by the shell step have been sourced
# before running.
ih::private::re-source() {
  #shellcheck disable=SC1091
  . "$HOME/.ih/augment.sh"
}
