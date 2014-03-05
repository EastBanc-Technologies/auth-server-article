#!/bin/bash

function base_dir() {
    local SOURCE="${1}"
    while [ -h "$SOURCE" ]; do # resolve $SOURCE until the file is no longer a symlink
        DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
        SOURCE="$(readlink "$SOURCE")"
        [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" # if $SOURCE was a relative symlink, we need to resolve it relative to the path where the symlink file was located
    done
    BASE_DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
    echo ${BASE_DIR}
}

#------------------------------------------------------------------------------
function askPassword() {
  local prompt="${1}"
  local pass
  read -sp "${prompt}: " pass
  echo ${pass};
}
#------------------------------------------------------------------------------
function askWithDefault() {
  local prompt="${1}"
  local default="${2}"
  local result="${default}"
  local input
  read -p "${prompt} [${default}]: " input
  if [ -n "${input}" ] ; then result=${input} ; fi
  echo ${result};
}

#------------------------------------------------------------------------------
function check_root() {
    if test "`id -u`" -ne 0
	    then
	    echo "You need to run this script as root!"
	    exit 1
    fi
}

#------------------------------------------------------------------------------
function process_templates_dir () {
    local source_dir=$1
    local result_dir=$2
    rm -Rf ${result_dir} && mkdir -p ${result_dir}
    local files=`find ${source_dir}/ -maxdepth 1 -type f -printf "%f\n"`
    for f in ${files}
        do
          echo "Processing template ${f} file..."
          process_template ${source_dir}/${f} ${result_dir}/${f}
        done
}

#------------------------------------------------------------------------------
function process_template () {
    awk '{while(match($0,"[$]{[^}]*}")) {var=substr($0,RSTART+2,RLENGTH -3);gsub("[$]{"var"}",ENVIRON[var])}}1' < $1 > $2
}

#------------------------------------------------------------------------------
function askFqdn(){
    local fqdn=`hostname -f`
    local input
    read -p "$1 [${fqdn}]:" input
    if [ -n "$input" ] ; then fqdn=${input} ; fi
    echo ${fqdn};
}

#------------------------------------------------------------------------------
function check_java() {

    if [ -z "$JAVA_HOME" ]; then
        echo "Please define JAVA_HOME environment variable before running this program"
        echo "setup program will use the JVM defined in JAVA_HOME for all the CLI tools"
        exit 1
    fi

    if [ ! -x "$JAVA_HOME"/bin/java ]; then
        echo "The defined JAVA_HOME environment variable is not correct"
        echo "setup program will use the JVM defined in JAVA_HOME for all the CLI tools"
        exit 1
    fi

    AWK=`which awk`
    if [ -z $AWK ]; then
        echo "setup fails because awk is not found"
        exit 1
    fi

    JAVA_VER=`${JAVA_HOME}/bin/java -version 2>&1 | $AWK -F'"' '{print $2}'`

    case $JAVA_VER in
        1.0* | 1.1* | 1.2* | 1.3* | 1.4* | 1.5* | 1.7*)
        echo "This program is designed to work with Java 1.6 Sun JDK only"
        exit 0
    ;;
esac

}
