. $LIB_DIR/colors.sh

error_msg() {
  echo -e "${COLOR_RED}ERROR:${COLOR_RESET} $1 " >&2;
}

notice() {
  echo -e "${COLOR_BOLD}notice:${COLOR_RESET} $1" >&2;
}

warning() {
  echo -e "${COLOR_YELLOW}warning:${COLOR_RESET} $1" >&2;
}

error_and_exit() {
  local switch=$1
  shift;
  case "$switch" in
    "1") 
      help;
      ;;
    "2") 
      error_msg "$1";
      ;;
    "3") 
      error_msg "$1";
      help;
      ;;
    "4")
      error_code=${1:-99};
      exit $error_code;
      ;;
    "5")
      help;
      error_code=${1:-99};
      exit $error_code;
      ;;
    "6")
      error_msg "$1";
      shift;
      error_code=${1:-99};
      exit $error_code;
      ;;
    "7")
      error_msg "$1";
      help;
      shift;
      error_code=${1:-99};
      exit $error_code;
      ;;
  esac;
}

must() {
  if ! eval "$1";
  then
    error_msg "$2";
    return 1;
  fi

  return 0;
}

must_not() {
  if eval "$1";
  then
    error_msg "$2";
    return 1;
  fi

  return 0;
}

check_arg_count() {
  local count=$1;
  shift;
  if [ $# -lt $count ];
  then
    error_and_exit 7 "More arguments required.";
  fi
}

must_be_root() {
  if [ $(id -u) -ne 0 ];
  then
    error_and_exit 6 "Must be super user.";
  fi
}
create_password() {
  local pass=$(must "apg -a 0 -M Ncl -n 6 -x 8 -m 3 -d" "Could not generate password.") \
    || return $?;

echo $pass;
}

