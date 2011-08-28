#!/bin/bash

. config
. $LIB_DIR/lahlib.sh

help() {
  echo -e "Usage:";
  echo -e "${COLOR_BOLD}$0${COLOR_RESET} name url";
  echo -e;
  echo -e "Create an alias for an existing world virtualhost.";
  echo -e "  ${COLOR_UNDERLINE}name${COLOR_RESET} The name of the world.";
  echo -e "  ${COLOR_UNDERLINE}url${COLOR_RESET} The alias to add.";
  echo -e;
}

must_be_root;

check_arg_count 2 $*;

WORLD_NAME=$1;
ALIAS=$2
WORLD_DOMAIN="${WORLD_NAME}.${DOMAIN}"
VHOST_FILE="${SITES_ENABLED}/${WORLD_NAME}";

[ -f "${VHOST_FILE}" ] || error_and_exit 6 "The vhost does not exist."

must "sed -i '/server_name/s/;$/ $ALIAS;/' $VHOST_FILE" \
     "Could not edit '$VHOST_FILE'." || exit 1;

nginx_reload || error_and_exit 6 "Could not restart nginx server please check."
