. $LIB_DIR/bashlib.sh

create_lxc_dir_from_template() {
  must_not "test -d $WORLD_DIR" \
           "Directory ${WORLD_DIR} already exists in ${LXC_DIR}." \
           || return 1;
  must     "cp -a $LXC_DIR/template $LXC_DIR/$WORLD_NAME 2>/dev/null;" \
           "Copy failed !" \
           || return 1;
}

configure_lxc_container() {
  local config_file=${WORLD_DIR}/config;
  local if_file=${WORLD_DIR}/rootfs/etc/network/interfaces;
  local nginx_file=${WORLD_DIR}/rootfs/etc/nginx/sites-available/world

  must "grep -q 'template' ${config_file}" \
       "No template to substitute in ${config_file}." \
        || return 1;
  must "grep -q '{ip_address}' ${if_file}" \
       "No '{ip_addr}' pattern in ${if_file}." \
        || return 1;
  must "grep -q 'template' ${nginx_file}" \
       "No 'template' pattern in ${nginx_file}." \
        || return 1;

  must "sed -i \"s/template/${WORLD_NAME}/\" ${config_file}" \
       "Error while parsing '${config_file}'." \
        || return 1;
  must "sed -i \"s/template/${WORLD_NAME}/\" ${nginx_file}" \
       "Error while parsing '${nginx_file}'." \
        || return 1;
  must "sed -i \"s/{ip_address}/$IP_ADDR/\" ${if_file}" \
       "Error while parsing '${if_file}'." \
        || return 1;
}

destroy_lxc_container() {
  must "lxc-ls | grep -q ${WORLD_NAME}" \
       "Could not find world '${WORLD_NAME}'." \
        || return 1;
  if lxc-info -n $WORLD_NAME 2>/dev/null | grep -qi 'running';
  then
    notice "LXC container is running, stoping it.";
    must "lxc-stop -n ${WORLD_NAME}" \
         "Could not stop world '${WORLD_NAME}'." \
          || return 1;
    sleep 3
  fi;
  must "rm -rf ${WORLD_DIR}" \
       "Could not delete LXC container '${WORLD_DIR}'." \
        || return 1;
}

create_ip_addr() {
  local result=$(must "echo \"SELECT major,max(minor) FROM ip_address WHERE major=(SELECT max(major) as max_maj FROM ip_address);\" | sqlite3 -batch -separator ' ' ${DB_FILE}" \
      "Could not query sqlite file '${DB_FILE}'.") \
      || return 1;

  local elts=(${result});
  let "elts[1]=elts[1]+1";
  let "elts[0]=elts[0]+elts[1]/256";
  let "elts[1]=elts[1]%256";
  must "echo \"INSERT INTO ip_address (major,minor,name) VALUES (${elts[0]},${elts[1]},'${WORLD_NAME}');\" | sqlite3 -batch ${DB_FILE}" \
      "Could not INSERT new ip values in the database file '${DB_FILE}'. Check for permissions." \
      || return 1;
  printf $NETWORK_MASK ${elts[0]} ${elts[1]};
}

delete_ip_addr() {
  local elts=(${IP_ADDR//./ });
  must "echo \"DELETE FROM ip_address WHERE major=${elts[2]} AND minor=${elts[3]};\" | sqlite3 -batch ${DB_FILE}" \
      "Could not DELETE from sqlite file '${DB_FILE}'. Check permissions." \
      || return 1;
}

get_ip_from_world() {
  local res=$(must "echo \"SELECT major, minor FROM ip_address WHERE name='${WORLD_NAME}';\" | sqlite3 -batch -separator ' ' ${DB_FILE}" \
    "Could not query sqlite file '${DB_FILE}' for table 'ip_address'.") \
    || return 1;
  must "[ \"$res\" != \"\" ]" \
    "No ip matching world '${WORLD_NAME}'." \
    || return 1;
  local elts=($res);
  printf $NETWORK_MASK ${elts[0]} ${elts[1]};
}

create_vhost_file() {
    must "grep -qi '{vhost_name}' ${SITES_AVAILABLE}/template" \
        "Could not find '{vhost_name}' pattern in '${SITES_AVAILABLE}/template'." \
        || return 1;
    must "sed 's/{vhost_name}/${WORLD_DOMAIN}/g' ${SITES_AVAILABLE}/template > ${SITES_AVAILABLE}/${WORLD_NAME}" \
        "Could not change '{vhost_name}' to '${WORLD_DOMAIN}' in '${WORLD_NAME}' in dir '${SITES_AVAILABLE}/template.'" \
        || return 1;
    must "grep -qi '{ip_address}' ${SITES_AVAILABLE}/${WORLD_NAME}" \
        "Could not find '{ip_address}' pattern in '${SITES_AVAILABLE}/${WORLD_NAME}'." \
        || return 2;
    must "sed -i 's/{ip_address}/${IP_ADDR}/' ${SITES_AVAILABLE}/${WORLD_NAME}" \
        "Could not parse '{ip_address}' in '${SITES_AVAILABLE}/${WORLD_NAME}'." \
        || return 2;
    must "ln -s {${SITES_AVAILABLE},${SITES_ENABLED}}/${WORLD_NAME}" \
        "Could not create symbolique link '${SITES_ENABLED}/${WORLD_NAME}'." \
        || return 2;
    nginx_reload || return 3;
}

delete_vhost_file() {
    must "rm {${SITES_AVAILABLE},${SITES_ENABLED}}/${WORLD_NAME}" \
        "Could not delete files '{${SITES_AVAILABLE},${SITES_ENABLED}}/${WORLD_NAME}'." \
        || return 1;
}

nginx_reload() {
    must "/etc/init.d/nginx reload > /dev/null 2>&1" \
        "Could not signal nginx process for config change" \
        || return 1;
}

query_db_server() {
  must "psql ${1} -U postgres --quiet -c \"${2}\"" \
    "Error while executing SQL query to the database server." \
    || return 1;
}

create_db_user() {
  local password=$(create_password) || return 1;
  local sql="CREATE USER \\\"${DB_USER}\\\" LOGIN PASSWORD '${password}';";
  query_db_server postgres "$sql" || return 1;
  echo ${password}
}

 create_database() {
  sql="CREATE DATABASE \\\"${WORLD_NAME}\\\" OWNER \\\"${DB_USER}\\\";";
  query_db_server postgres "$sql" || return 1;
}

create_schema() {
  sql="BEGIN; CREATE SCHEMA \\\"${DB_USER}\\\" AUTHORIZATION \\\"${DB_USER}\\\"; GRANT ALL ON SCHEMA \\\"${DB_USER}\\\" TO \\\"${DB_USER}\\\"; COMMIT;";
  query_db_server ${WORLD_NAME} "$sql" || return 1;
}

destroy_db_user() {
  local sql="DROP USER \\\"${DB_USER}\\\";";
  query_db_server postgres "$sql" || return 1;
}

destroy_db() {
  local sql="DROP DATABASE \\\"${WORLD_NAME}\\\";";
  query_db_server postgres "$sql" || return 1;
}

destroy_schema() {
  sql="DROP SCHEMA \\\"${DB_USER}\\\" CASCADE;";
  query_db_server ${WORLD_NAME}  "$sql" || return 1;
}

create_db() {
  psql ${WORLD_NAME} -U postgres --quiet --set ON_ERROR_STOP= <<EOSQL 2>/dev/null
BEGIN;
CREATE SCHEMA "${DB_USER}" AUTHORIZATION "${DB_USER}";
REVOKE ALL PRIVILEGES ON SCHEMA public FROM public;
GRANT ALL PRIVILEGES ON SCHEMA public TO "${DB_USER}" WITH GRANT OPTION;
GRANT USAGE ON SCHEMA public TO public;
GRANT ALL PRIVILEGES ON LANGUAGE plpgsql TO "${DB_USER}";
COMMIT;
EOSQL
  case "$?" in
    "1"|"2")
      error_msg "Error while connecting to the database.";
      return 1;
      ;;
    "3")
      error_msg "Creation transaction failed (rollback).";
      return 1;
      ;;
  esac
}

create_db_schema() {
  local password=$(create_password) || return 1;
  psql ${WORLD_NAME} -U postgres --quiet --set ON_ERROR_STOP= <<EOSQL
BEGIN;
CREATE ROLE "${DB_USER}" LOGIN PASSWORD '${password}';
CREATE SCHEMA "${DB_USER}" AUTHORIZATION "${DB_USER}";
COMMIT;
EOSQL
  case "$?" in
    "1"|"2")
      error_msg "Error while connecting to the database.";
      return 1;
      ;;
    "3")
      error_msg "Creation transaction failed (rollback).";
      return 1;
      ;;
  esac

echo $password;
}

destroy_db_users() {
  psql postgres -U postgres --quiet --set ON_ERROR_STOP= <<EOSQL
BEGIN;
DELETE FROM pg_authid WHERE rolname ~ '^${WORLD_NAME}/';
COMMIT;
EOSQL
  case "$?" in
    "1"|"2")
      error_msg "Error while connecting to the database.";
      return 1;
      ;;
    "3")
      error_msg "Delete user transaction failed (rollback).";
      return 1;
      ;;
  esac
}

add_user_pg_hba() {
  must_not "grep -q '${DB_USER}' ${PG_HBA}" \
    "The user is already registered in pg_hba. Please check." \
    return 1;

  must "grep {db_name} ${PG_HBA} | sed 's/^#//' | sed 's/{db_name}/${WORLD_NAME}/' | sed 's:{user_name}:${DB_USER}:' >> ${PG_HBA}" \
    "Could not add entry in ph_hba." \
    return 1;

  postgresql_reload || return 1;
}

remove_pg_hba() {
  must "grep -q '${DB_USER}' ${PG_HBA}" \
    "The user is not registered in pg_hba. Please check." \
    return 1;

  must "sed -i '\\#${DB_USER}#d' ${PG_HBA}" \
    "Could not remove entry from pg_hba." \
    return 1;

  postgresql_reload || return 1;
}

remove_pg_hbas() {
  must "sed -i '\\#${WORLD_NAME}/#d' ${PG_HBA}" \
    "Could NOT remove pg_hba entries. Please check." \
    return 1;

  postgresql_reload || return 1;
}

postgresql_reload() {
  must "/etc/init.d/postgresql reload 2>/dev/null" \
    "Could not signal postgresql for reloading configuration." \
    return 1;
}

configure_world_application() {
  local bootstrap_file=${WORLD_DIR}/rootfs/var/www/world/bootstrap.php

  must "grep -qi '{db-password}' ${bootstrap_file} && grep -qi '{db-host}' ${bootstrap_file} && grep -qi '{world}' ${bootstrap_file}" \
        "Expexted pattern not found in '${bootstrap_file}'." \
        || return 1; 
  must "sed -i \"s/{db-password}/${DB_PASS}/g\" ${bootstrap_file}" \
       "Error while parsing '${bootstrap_file}'." \
        || return 1;
  must "sed -i \"s/{db-host}/${DB_HOST}/g\" ${bootstrap_file}" \
       "Error while parsing '${bootstrap_file}'." \
        || return 1;
  must "sed -i \"s/{world}/${WORLD_NAME}/g\" ${bootstrap_file}" \
       "Error while parsing '${bootstrap_file}'." \
        || return 1;
  must "chroot --userspec=33.33 ${WORLD_DIR}/rootfs /usr/bin/php /var/www/world/install.php 2>/dev/null" \
        "Could not execute the configuration script 'install.php' in world." \
        || return 1;
}
