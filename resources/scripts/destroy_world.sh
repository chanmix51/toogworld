#!/bin/bash

. config
. $LIB_DIR/lahlib.sh

help() {
  echo "Usage:";
  echo "${COLOR_BOLD}$0${COLOR_RESET} name";
  echo;
  echo "Remove a world LXC container with all files and processes.";
  echo "       ${COLOR_UNDERLINE}name${COLOR_RESET} The name of the world.";
  echo;
}

must_be_root;

check_arg_count 1 $@;

WORLD_NAME=$1;
WORLD_DIR=$LXC_DIR/$WORLD_NAME;

if ! destroy_lxc_container;
then
  error_and_exit 6 "Problem while destroying LXC container ${WORLD_NAME}. Aborting.";
fi
