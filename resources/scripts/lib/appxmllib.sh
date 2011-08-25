get_dependencies() {
    check_arg_count 1 $*;

    local dep=$(must "xmlstarlet sel -t -m '/package/dependencies/dependency' -v @type -n $1" \
        "Error while parsing file '$1'.") || return 1

    echo $dep;
}

get_init_file() {
    check_arg_count 2 $*;

    local init_file=$(must "xmlstarlet sel -t -m '/package/dependencies/dependency[@type=\"$2\"]/resource[@type=\"init-file\"]' -v . $1" \
        "Error while parsing file '$1'.") || return 1

    echo $init_file;
}

get_application_files() {
    check_arg_count 2 $*;

    local application_files=$(must "xmlstarlet sel -t -m '/package/dependencies/dependency[@type=\"$2\"]/resource[@type=\"application-files\"]/files/file' -v @name -n $1" \
        "Error while parsing file '$1'.") || return 1

    echo $application_files;
}

get_application_files_parameters() {
    check_arg_count 2 $*;

    local application_files_parameters=$(must "xmlstarlet sel -t -m '/package/dependencies/dependency[@type=\"$2\"]/resource[@type=\"application-files\"]/parameters/parameter' -v @name -n $1" \
        "Error while parsing file '$1'.") || return 1

    echo $application_files_parameters;
}
