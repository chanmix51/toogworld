#!/bin/bash

. config
. $LIB_DIR/lahlib.sh

help() {
  echo -e "Usage:";
  echo -e "${COLOR_BOLD}$0${COLOR_RESET} world name";
  echo -e;
  echo -e "Create a schema for a tool in the database.";
  echo -e "  ${COLOR_UNDERLINE}world${COLOR_RESET} The name of the world.";
  echo -e "  ${COLOR_UNDERLINE}name${COLOR_RESET} The name of the tool.";
  echo -e;
}

must_be_root;

check_arg_count 2 $*;

WORLD_NAME=$1;
TOOL_NAME=$2;
DB_USER="${WORLD_NAME}°${TOOL_NAME}";

password=$(create_db_schema)  || error_and_exit 6 "Could not create database schema.";
echo $password;

add_user_pg_hba || error_and_exit 6 "Error while setting up ACLs.";

exit 0;
