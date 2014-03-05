#!/bin/bash

check_root
check_java
source ${BASE_DIR}/scripts/opendj/common.sh


echo ""
echo ""
echo ""
echo "                        OpenDJ  Installation                           "
echo "                                                                       "
echo "                                                                       "
echo "                                                                       "

# 1. Prepare list of variables needs to be passed into configuration file templates

echo
echo "Setup OpenDJ password:"
LDAP_PASSWORD=`askPassword "Enter password"`
printf '\n'
LDAP_PASSWORD_CONFIRM=`askPassword "Confirm password"`
printf '\n'

if [ "$LDAP_PASSWORD" != "$LDAP_PASSWORD_CONFIRM" ]
    then
       echo "Entered passwords do not match"
       exit 1;
fi

echo ""
echo ""
echo ""
echo "                        Installation configuration summury             "
echo "                                                                       "
echo "                                                                       "
echo "                                                                       "
echo "Install directory    : ${INSTALL_DIR}"
echo ""
echo ""
PROCEED=`askWithDefault "Do you want to proceed installation? (Y|n)" "n"`
if [ "${PROCEED}" != "Y" ] && [ "${PROCEED}" != "y" ]
    then
       echo "Quit installation process"
       exit 0;
fi

export LDAP_PASSWORD INSTALL_DIR



# 2. Process configuration files templates

echo ""
echo "Process configuration files templates"
TEMPLATES_DIR=${BASE_DIR}/conf/opendj
CONF_SOURCE_DIR=${BASE_DIR}/tmp/opendj/

process_templates_dir ${TEMPLATES_DIR} ${CONF_SOURCE_DIR}
echo "Templates processed"
echo ""


# 3. Check that user/group exists and create if it does not

echo ""
echo "Check group exists: $GROUP"
getent group $GROUP > /dev/null || groupadd -r $GROUP
echo "Check user exists: $USER"
getent passwd $USER > /dev/null || useradd -r  -c "auth-server system user" -d /usr/local/lib/auth-server -g $GROUP $USER
echo "Check configuration dir exists"
mkdir -p ${CONF_DIR}
echo "Create installation directory ${INSTALL_DIR}"
mkdir -p ${INSTALL_DIR}


# 4. Extract OpenDJ to ${INSTALL_DIR}

echo ""
echo "Extract OpenDJ distribution..."
#tar --extract --file=${OPENDJ_DISTR} --strip-components=1 --directory=${INSTALL_DIR}
tempdir=`mktemp -d`
unzip -q "${OPENDJ_DISTR}" -d "${tempdir}"
mv ${tempdir}/opendj/* ${INSTALL_DIR}
rm -Rf $tempdir


# 5. Put custom config files to ${INSTALL_DIR} and start OpenDJ setup process

echo ""
echo "Copy OpenDJ config files..."
cp ${CONF_SOURCE_DIR}/ldap-init-config.ldif ${INSTALL_DIR}/
cp ${CONF_SOURCE_DIR}/ldap-structure.ldif ${INSTALL_DIR}/
cp ${CONF_SOURCE_DIR}/ldap-default-permissions.ldif ${INSTALL_DIR}/
cp ${CONF_SOURCE_DIR}/opendj.properties ${INSTALL_DIR}/
cp ${CONF_SOURCE_DIR}/java.properties ${INSTALL_DIR}/config/java.properties

chown -R ${USER}:${GROUP} ${INSTALL_DIR}
echo "Launch OpenDJ setup process..."
cd ${INSTALL_DIR}
su ${USER} -c "./setup --cli --propertiesFilePath opendj.properties --no-prompt --acceptLicense"



# 6. Modify OpenDJ indexes and rebuild updated ones to validate them.

echo "Initialize OpenDJ with default LDAP data..."
su ${USER} -c 'bin/import-ldif -h localhost -p 4444 -D "cn=Directory Manager" -w ${LDAP_PASSWORD} -b dc=eastbanctech,dc=com -n userRoot -l ldap-init.ldif -X'




# 7. Register OpenDJ as ${SERVICE_NAME} system service
echo "Register ${SERVICE_NAME} service"
cp ${BASE_DIR}/scripts/opendj/service.sh /etc/init.d/${SERVICE_NAME}
cp ${CONF_SOURCE_DIR}/opendj-service.cfg ${CONF_FILE}

# Set file permissions
chmod 755 /etc/init.d/${SERVICE_NAME}
chown -R $USER:$GROUP $INSTALL_DIR

# Make service
chkconfig --add ${SERVICE_NAME}
chkconfig ${SERVICE_NAME} on

echo ""
echo ""
echo "Package OpenDJ was successfully installed!"
echo ""
echo ""