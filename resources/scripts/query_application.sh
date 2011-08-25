#!/bin/bash

. config
. $LIB_DIR/lahlib.sh

help() {
  echo -e "Usage:";
  echo -e "${COLOR_BOLD}$0${COLOR_RESET} type";
  echo -e;
  echo -e "Check if an application exists and dump its requirements.";
  echo -e "  ${COLOR_UNDERLINE}type${COLOR_RESET} The application type.";
  echo -e;
}

must_be_root;

check_arg_count 1 $*;
APP_NAME=$1;

check_arg_non_empty $APP_DIR || error_and_exit 6 "'APP_DIR' variable must be set in configuration.";

requirements=$(dump_application_requirements) || error_and_exit 6 "Error while querying application '${APP_NAME}'.";

echo $requirements;
