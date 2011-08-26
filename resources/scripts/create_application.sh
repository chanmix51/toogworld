#!/bin/bash

. config
. $LIB_DIR/lahlib.sh

help() {
  echo -e "Usage:";
  echo -e "${COLOR_BOLD}$0${COLOR_RESET} type name world";
  echo -e;
  echo -e "Instanciate a new application in a world.";
  echo -e "  ${COLOR_UNDERLINE}type${COLOR_RESET} The type of the application.";
  echo -e "  ${COLOR_UNDERLINE}name${COLOR_RESET} The name of the application.";
  echo -e "  ${COLOR_UNDERLINE}world${COLOR_RESET} The name of the world.";
  echo -e;
}

must_be_root;

check_arg_count 3 $*;
check_arg_non_empty $PACKAGE_DIR || error_and_exit 6 "'PACKAGE_DIR' variable must be set in configuration.";
check_arg_non_empty $LXC_DIR || error_and_exit 6 "'LXC_DIR' variable must be set in configuration.";

APP_TYPE=$1
APP_NAME=$2
WORLD_NAME=$3
WORLD_DIR=${LXC_DIR}/${WORLD_NAME}
TARGET_DIR=${WORLD_DIR}/rootfs/var/www/world/applications/${APP_NAME}
APP_DIR="${PACKAGE_DIR}/${APP_TYPE}"

remove_files() {
  rm -r $TARGET_DIR && info "Removed dir '$TARGET_DIR'." || warning "Could not remove '$TARGET_DIR', please check.";
}

remove_config() {
  rm -r "$WORLD_DIR/rootfs/etc/nginx/sites-available/${APP_NAME}.conf" && info "Removed nginx configuration file." || warning "Could NOT remove nginx configuration file."
}

. ./lib/appxmllib.sh

install_application_files;
rc=$?
if [ $rc -gt 0 ];
then
    if [ $rc -eq 2 ];
    then
        remove_files
    fi
    exit 1;
fi

create_application_vhost
rc=$?;
if [ $rc -gt 0 ];
then
    if [ $rc -eq 2 ];
    then
        remove_config;
    fi
    remove_files;
    exit 1;
fi
