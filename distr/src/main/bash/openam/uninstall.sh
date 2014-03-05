#!/bin/bash

source ${BASE_DIR}/scripts/openam/common.sh

echo "Uninstalling OpenAM..."
echo "Stopping ${SERVICE_NAME} service..."
set +e
service ${SERVICE_NAME} stop
echo "Remove installed application directory: ${INSTALL_DIR}"
rm -Rf ${INSTALL_DIR}
echo "Remove configuration file: ${CONF_FILE}"
rm -f ${CONF_FILE}
echo "Unregister ${SERVICE_NAME} service"
chkconfig --del ${SERVICE_NAME}
chkconfig ${SERVICE_NAME} off
rm -f /etc/init.d/${SERVICE_NAME}
set -e
echo "Package OpenAM was successfully uninstalled"