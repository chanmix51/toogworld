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
NGINX_DIR=${WORLD_DIR}/rootfs/etc/nginx

cd $NGINX_DIR/sites-enabled || error_and_exit 6 "Could not cd to '$NGINX_DIR/sites-enabled'."
ln -s ../sites-available/${APP_NAME}.conf || error_and_exit 6 "Could not create symbolic link."
cd -

pid=$(lxc-ps --name ${WORLD_NAME} u | grep -i nginx | awk '/root/ { print $3 }');
check_arg_non_empty $pid || error_and_exit 6 "Could not get nginx PID in LXC ${WORLD_NAME}.";

kill -HUP $pid  || error_and_exit 6 "Could not signal nginx process '$pid'.";

