#!/bin/bash

. config
. $LIB_DIR/lahlib.sh

help() {
  echo -e "Usage:";
  echo -e "${COLOR_BOLD}$0${COLOR_RESET} world name type db_host db_password";
  echo -e;
  echo -e "Configure the application for the SQL dependency.";
  echo -e "  ${COLOR_UNDERLINE}world${COLOR_RESET} The world name";
  echo -e "  ${COLOR_UNDERLINE}name${COLOR_RESET} The application name.";
  echo -e "  ${COLOR_UNDERLINE}type${COLOR_RESET} The application type.";
  echo -e "  ${COLOR_UNDERLINE}db_host${COLOR_RESET} The database server host or ip.";
  echo -e "  ${COLOR_UNDERLINE}db_password${COLOR_RESET} The password associated with the created account for this application.";
  echo -e;
}

must_be_root;

check_arg_count 5 $*;
WORLD_NAME=$1
APP_NAME=$2;
APP_TYPE=$3
DB_HOST=$4
DB_PASSWORD=$5
APP_DIR=${PACKAGE_DIR}/${APP_TYPE}
WORLD_DIR="${LXC_DIR}/${WORLD_NAME}";
TARGET_DIR="${WORLD_DIR}/rootfs/var/www/applications/${APP_NAME}"

. ./lib/appxmllib.sh

parse_application_files sql || error_and_exit 6 "Error while configuring the SQL in application '${APP_NAME}'."

launch_sql_startup_file || error_and_exit 6 "Error while launching SQL startup file for '${APP_NAME}'.";
