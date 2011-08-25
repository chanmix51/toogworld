#!/bin/bash

. config
. $LIB_DIR/lahlib.sh

help() {
  echo -e "Usage:";
  echo -e "${COLOR_BOLD}$0${COLOR_RESET} world name";
  echo -e;
  echo -e "Configure the application for the SQL dependency.";
  echo -e "  ${COLOR_UNDERLINE}world${COLOR_RESET} The world name";
  echo -e "  ${COLOR_UNDERLINE}name${COLOR_RESET} The application name.";
  echo -e;
}

must_be_root;

check_arg_count 2 $*;
WORLD_NAME=$1
APP_NAME=$2

WORLD_DIR=${LXC_DIR}/${WORLD_NAME}
NGINX_DIR=${WORLD_NAME}/rootfs/etc/nginx

ln -s $NGINX_DIR/sites-{available,enabled}/${APP_NAME}.conf || error_and_exit 6 "Could not create symbolic link."

nginx_reload || error_and_exit 6 "Error while reloading nginx."
