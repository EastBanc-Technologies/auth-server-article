#!/bin/bash

DIST_DIR=${BASE_DIR}/lib
TOMCAT_DISTR="${DIST_DIR}/tomcat-${TOMCAT_VERSION}.tar.gz"
OPENAM_DISTR="${DIST_DIR}/openam-server-${OPENAM_VERSION}.war"
OPENDJ_DISTR="${DIST_DIR}/opendj-server-${OPENDJ_VERSION}.zip"
OPENAM_CONFIG_TOOLS="${DIST_DIR}/openam-distribution-ssoconfiguratortools-${OPENAM_VERSION}.zip"
OPENAM_ADMIN_TOOLS="${DIST_DIR}/openam-distribution-ssoadmintools-${OPENAM_VERSION}.zip"

GROUP=openam
USER=openam
PREFIX=/usr/local/lib
CONF_DIR=/etc/auth-server
export GROUP USER PREFIX BASEDIR DIST_DIR


