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
  parse_model_base_file || return 1;
  must "chroot --userspec=33.33 ${WORLD_DIR}/rootfs /usr/bin/php /var/www/world/install.php >/dev/null" \
        "Could not execute the configuration script 'install.php' in world." \
        || return 1;
}

parse_model_base_file() {
  local file;
  for file in ${WORLD_DIR}/rootfs/var/www/world/Model/Pomm/Entity/Toogworld/Base/*; 
  do
    must "sed -i \"s/{world}/${WORLD_NAME}/g\" ${file}" \
         "Error while parsing model file '${file}'." \
         || return 1;
  done
}

dump_application_requirements() {
    local application_file="$APP_DIR/package/application.xml";

    must "[ -d $APP_DIR ]" \
         "The directory '${dir}' does not exist." \
         || return 1
    must "[ -f $application_file ]" \
         "Package file '${application_file}' does not exists." \
         || return 1;

    local req=$(get_dependencies ${application_file}) || return 2

    echo $req;
} 

install_application_files() {
    must_not "[ -d "$TARGET_DIR" ]" \
        "Application '${APP_NAME}' already exists in world '${WORLD_NAME}'." \
        || return 1;
    must "mkdir $TARGET_DIR" \
        "Cannot create directory '${TARGET_DIR}'." \
        || return 1;
    must "cp -r ${APP_DIR}/source/* ${TARGET_DIR}/" \
        "Error while copying files to the world '${WORLD_NAME}'." \
        || return 2;
}

check_application_files_parameters() {
    local parameters;

    define -a parameters=$(get_application_files_parameters ${application_file} $1) || return 1;

    for parameter in ${parameters[@]};
    do
        case ${parameter} in
            "db_host")
                check_arg_non_empty ${DB_HOST} || return 1
                db_host=${DB_HOST}
                ;;
            "db_password")
                check_arg_non_empty ${DB_PASSWORD} || return 1
                db_password=${DB_PASSWORD}
                ;;
            "db_name")
                check_arg_non_empty ${WORLD_NAME} || return 1
                db_name=${WORLD_NAME};
                ;;
            "db_user")
                check_arg_non_empty ${WORLD_NAME} || return 1
                check_arg_non_empty ${APP_NAME}   || return 1
                db_user="${WORLD_NAME}°${APP_NAME}"
                ;;
            "vhost-name")
                check_arg_non_empty ${WORLD_NAME} || return 1
                check_arg_non_empty ${DOMAIN} || return 1
                vhost_name="${APP_NAME}.${WORLD_NAME}.${DOMAIN}"
                ;;
            "root_dir")
                check_arg_non_empty ${TARGET_DIR} || return 1
                root_dir="${TARGET_DIR}"
                ;;
            "tcp_port")
                error_msg "'tcp_port' is NOT implemented yet."
                return 1;
                ;;
            *)
                error_msg "Parameter '${parameter}' is unknown."
                return 1;
        esac
    done
}

create_application_vhost() {
    local application_file="${APP_DIR}/package/application.xml";
    local conf_file="${WORLD_DIR}/rootfs/etc/nginx/sites-available/${APP_NAME}.conf";
    local vhost_file;
    local parameters;

    must "check_application_files_parameters nginx"                                    || return 1;
    define -a vhost_file=$(get_application_files ${application_file} nginx)            || return 1;
    define -a parameters=$(get_application_files_parameters ${application_file} nginx) || return 1;

    must "[ ${#vhost_file[@]} -eq 1 ]" \
         "Bad vhost file read from ${application_file}." \
         || return 1;

    must "cp ${APP_DIR}/package/$vhost_file ${conf_file}" \
         "Could not copy application nginx config file." \
         || return 1;

    for parameter in ${parameters[@]};
    do
        must "sed -i \"s/{${parameter}}/$(eval echo \\\$${parameter})/g\" $conf_file" \
             "Could not parse ${conf_file} for parameter ${parameter}." \
             || return 2;
    done
}

parse_application_files() {
    local type=$1;
    check_arg_non_empty $type || return 1;
    local application_file="${APP_DIR}/package/application.xml";

    must "check_application_files_parameters sql"                                      || return 1;
    define -a app_files=$(get_application_files ${application_file} $type)             || return 1;
    define -a parameters=$(get_application_files_parameters ${application_file} $type) || return 1;

    for file in ${app_files[0]};
    do
        for parameter in ${parameters[@]};
        do
            must "sed -i \"s/{${parameter}}/$(eval echo \\\$${parameter})/g\" ${TARGET_DIR}/${file}" \
                "Could not parse '${TARGET_DIR}/${file} for parameter '${parameter}'." \
                || return 2;
        done
    done
}

launch_sql_startup_file() {
    local type=$1;
    check_arg_non_empty $type || return 1;
    local application_file="${APP_DIR}/package/application.xml";

    init_file=$(get_init_file ${application_file} ${type}) || return 1;

    if [ "$init_file" == "" ];
    then
        return 0;
    fi

    export PGPASSFILE="/tmp/.pgpass.${RANDOM}"
    echo "${DB_HOST}::${WORLD_NAME}:${WORLD_NAME}°${APP_NAME}:${DB_PASSWORD}" > $PGPASSFILE
    chmod 600 $PGPASSFILE

    psql ${WORLD_NAME} -U "${WORLD_NAME}°${APP_NAME}" -h ${DB_HOST} < $APP_DIR/package/${init_file}
    local fail=$?

    [ $fail -ne 0 ] && error_msg "Error while connecting to the database '${WORLD_NAME}' -U '${WORLD_NAME}°${APP_NAME}' -h '${DB_HOST}'.";

    rm $PGPASSFILE || warning "Could not delete '${PGPASSFILE}'. It contains access credentials for user '${WORLD_NAME}°${APP_NAME}'.";

    return $fail;
}

