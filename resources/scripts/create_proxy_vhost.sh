#!/bin/bash

. config
. $LIB_DIR/lahlib.sh

help() {
  echo -e "Usage:";
  echo -e "${COLOR_BOLD}$0${COLOR_RESET} name";
  echo -e;
  echo -e "Create a proxy virtualhost to redirect http queries to the world.";
  echo -e "  ${COLOR_UNDERLINE}name${COLOR_RESET} The name of the world (will create the domain ${COLOR_UNDERLINE}name.toogworld.net${COLOR_RESET}).";
  echo -e;
}

must_be_root;

check_arg_count 1 $*;

WORLD_NAME=$1;
WORLD_DOMAIN="${WORLD_NAME}.toogworld.net";

IP_ADDR=$(create_ip_addr);
if [ $? -ne 0 ];
then
  error_and_exit 6 "Cannot generate IP address for LXC instance. Quitting.";
fi

create_vhost_file;
ret=$?;
if [ $ret -gt 0 ];
then
  error_and_exit 2 "Error while creating vhost file.";
  if [ $ret -ge 2 ];
  then
    delete_vhost_file \
      && notice "Rollback config changes." \
      || warning "Could NOT Rollback config changes (none made ?).";
  fi
  if [ $ret -ge 3 ];
  then
    nginx_reload \
      && notice "Nginx has been reloaded." \
      || warning "Could not signal nginx.";
  fi
  delete_ip_addr ${IP_ADDR} \
    && notice "Successfully rollback IP address '${IP_ADDR}' in database." \
    || warning "Could NOT rollback IP address '${IP_ADDR}' in database.";
  error_and_exit 6 "Quitting.";
fi

exit 0;
