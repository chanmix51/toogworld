#!/bin/bash

. config
. $LIB_DIR/lahlib.sh

help() {
  echo -e "Usage:";
  echo -e "${COLOR_BOLD}$0${COLOR_RESET} name";
  echo -e;
  echo -e "Create a database for the given world.";
  echo -e "  ${COLOR_UNDERLINE}name${COLOR_RESET} The name of the world (will create the database ${COLOR_UNDERLINE}name${COLOR_RESET}).";
  echo -e;
}

must_be_root;

check_arg_count 1 $*;

WORLD_NAME=$1;
DB_USER="${WORLD_NAME}°world";
HOST_NAME='localhost';

password=$(create_db_user) || error_and_exit 6 "Cannot create database user.";

echo $password;
echo ${HOST_NAME};

if ! create_database;
then
  error_and_exit 2 "Error while creating database.";
  destroy_db_user \
    || warning "Could not roll back user creation." \
    && notice  "Rollback user creation.";
  exit 1;
fi

create_db       || error_and_exit 6 "Error while setting up database.";
add_user_pg_hba || error_and_exit 6 "Error while setting up ACLs.";

exit 0;
