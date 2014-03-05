#!/bin/bash

# exit immediately if error
set -e

# "import" utility functions
source ${SCRIPTS_DIR}/utils.sh

# correctly identify base directory even if script is run from another directory.
BASE_DIR=`base_dir "${BASH_SOURCE[0]}"`
SCRIPTS_DIR=${BASE_DIR}/scripts
# read domain name
DOMAIN=`hostname -d`
FQDN=`hostname`

# read settings filtered by Maven (Maven-bash bridge)
source ${SCRIPTS_DIR}/build.properties

# read other settings specific for installation: config dir, installation path, etc...
source ${SCRIPTS_DIR}/env.sh

echo
echo
echo ""
echo "                        Auth-Server Installation Script                "
echo "                                                                       "
echo "                                                                       "
echo "                                                                       "

echo "  VERSION:           $VERSION"
echo "  BUILD_DATE:        $BUILD_DATE"
echo
echo "  BASE_DIR:          $BASE_DIR"
echo "  INSTALL_DIR:       $PREFIX"
echo "  JAVA_HOME:         $JAVA_HOME"
echo "  DOMAIN:            $DOMAIN"
echo "  OPENAM VERSION:    $OPENAM_VERSION"
echo "  OPENDJ VERSION:    $OPENDJ_VERSION"
echo
echo

check_root
check_java

function printUsage {
    echo
    echo "./main openam install  -  setup OpenAM server"
    echo "./main opendj install  -  setup OpenDJ server"
    echo
    echo
    echo "./main openam uninstall  -  uninstall OpenAM server"
    echo "./main opendj uninstall  -  uninstall OpenDJ server"
    echo
}

if [ $# -eq 0 ]
  then
    printUsage
    exit 0
fi


case "$1" in
    openam) PROGRAM="openam"
            ;;
    opendj) PROGRAM="opendj"
            ;;
    help)   printUsage
            exit 0
            ;;
    *)      printUsage
            exit 1
            ;;
esac

case "$2" in
    install) . ${SCRIPTS_DIR}/${PROGRAM}/install.sh
            ;;
    uninstall) . ${SCRIPTS_DIR}/${PROGRAM}/uninstall.sh
            ;;
    *)      printUsage
            ;;
esac


