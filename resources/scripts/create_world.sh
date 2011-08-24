#!/bin/bash

. config
. $LIB_DIR/lahlib.sh

help() {
  echo -e "Usage:";
  echo -e "${COLOR_BOLD}$0${COLOR_RESET} name ip db_user db_password db_host";
  echo;
  echo -e "Create a pre configured LXC container with a world application.";
  echo -e "       ${COLOR_UNDERLINE}name${COLOR_RESET} The name of the world will also be the LXC container name.";
  echo -e "         ${COLOR_UNDERLINE}ip${COLOR_RESET} The ip address to bind the container with.";
  echo -e "${COLOR_UNDERLINE}db_password${COLOR_RESET} The associated password.";
  echo -e "    ${COLOR_UNDERLINE}db_host${COLOR_RESET} The database network address.";
  echo;
}

must_be_root;

check_arg_count 4 $*;

WORLD_NAME=$1;
WORLD_DIR=$LXC_DIR/$WORLD_NAME;
IP_ADDR=$2;
DB_PASS=$3;
DB_HOST=$4;

if ! create_lxc_dir_from_template $WORLD_NAME;
then
  error_and_exit 6 "Error while creating LXC container.";
fi

if ! configure_lxc_container;
then
  error_and_exit 6 "Error while configuring the container. Leaving unconfigured.";
fi

if ! configure_world_application;
then
  error_and_exit 6 "Errors while configuring the world application. Leaving unconfigured.";
fi

if ! lxc-start -n $WORLD_NAME -d;
then
  error_and_exit 6 "Error while starting the LXC container.";
fi
