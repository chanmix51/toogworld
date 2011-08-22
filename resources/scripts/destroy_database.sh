#!/bin/bash

. config
. $LIB_DIR/lahlib.sh

help() {
  echo -e "Usage:";
  echo -e "${COLOR_BOLD}$0${COLOR_RESET} name";
  echo -e;
  echo -e "Drop the database for the given world.";
  echo -e "  ${COLOR_UNDERLINE}name${COLOR_RESET} The name of the world (will drop the database ${COLOR_UNDERLINE}name${COLOR_RESET}).";
  echo -e;
}

must_be_root;

check_arg_count 1 $*;

WORLD_NAME=$1;
DB_USER="${WORLD_NAME}/world";

destroy_db       || error_and_exit 6 "Error in dropping world '${WORLD_NAME}'."
destroy_db_users || error_and_exit 6 "Error in dropping users '${DB_USER}'."
remove_pg_hbas   || error_and_exit 6 "Could not remove ACLs."

exit 0;
