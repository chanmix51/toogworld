#!/bin/bash

. config
. $LIB_DIR/lahlib.sh

help() {
  echo -e "Usage:";
  echo -e "${COLOR_BOLD}$0${COLOR_RESET} name";
  echo -e;
  echo -e "Destroy a proxy virtualhost configuration.";
  echo -e "  ${COLOR_UNDERLINE}name${COLOR_RESET} The name of the world.";
  echo -e;
}

must_be_root;

check_arg_count 1 $*;

WORLD_NAME=$1;
IP_ADDR=$(get_ip_from_world) \
  || error_and_exit 6 "Could not get IP '${IP_ADDR}' from world name '${WORLD_NAME}'.";

delete_vhost_file || error_and_exit 6 "Could not delete vhost.";
delete_ip_addr    || error_and_exit 6 "Could not delete IP address from database.";
nginx_reload      || error_and_exit 6 "Could not signal nginx for changes";
