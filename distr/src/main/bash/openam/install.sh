#!/bin/bash

check_root
check_java
source ${BASE_DIR}/scripts/openam/common.sh

echo ""
echo ""
echo ""
echo "                        OpenAM Installation                            "
echo "                                                                       "
echo "                                                                       "
echo "                                                                       "


# 1. Prepare list if variables needs to be passed into configuration file templates
FQDN=`askWithDefault "Enter fully qualified domain name" "$FQDN"`
COOKIE_DOMAIN=`askWithDefault "Cookie domain" "$DOMAIN"`
echo
echo "Setup new OpenAM admininistrator password:"
read -p "Note! OpenAM and OpenDJ passwords must be different. Press any key to proceed"
ADMIN_PASSWORD=`askPassword "Enter new password"`
printf '\n'
ADMIN_PASSWORD_CONFIRM=`askPassword "Confirm password"`
printf '\n'
if [ "$ADMIN_PASSWORD" != "$ADMIN_PASSWORD_CONFIRM" ]
    then
       echo "Entered passwords do not match"
       exit 1;
fi
echo
LDAP_HOSTNAME=`askWithDefault "Enter hostname of OpenDJ server" "$FQDN"`
LDAP_PASSWORD=`askPassword "Enter OpenDJ administrator password"`
echo


echo ""
echo ""
echo ""
echo "                        Installation configuration summury             "
echo "                                                                       "
echo "                                                                       "
echo "                                                                       "
echo "Install directory    : ${INSTALL_DIR}"
echo "OpenAM hostname      : ${FQDN}"
echo "OpenAM cookie domain : ${COOKIE_DOMAIN}"
echo "OpenAM log directory : ${LOG_DIR}"
echo "OpenDJ hostname      : ${LDAP_HOSTNAME}"
echo ""
echo ""
PROCEED=`askWithDefault "Do you want to proceed installation? (Y|n)" "n"`
if [ "${PROCEED}" != "Y" ] && [ "${PROCEED}" != "y" ]
    then
       echo "Quit installation process"
       exit 0;
fi

OPENAM_STATS_MODE=off   #  Possible values for the key 'state' are: off | file | console
TEMPLATES_DIR=${BASE_DIR}/conf/openam
CONF_SOURCE_DIR=${BASE_DIR}/tmp/openam
PWD_FILE=${BASE_DIR}/temp
rm -f ${PWD_FILE}
echo ${ADMIN_PASSWORD} > ${PWD_FILE}
chmod 400 ${PWD_FILE}

export FQDN LDAP_HOSTNAME INSTALL_DIR LOG_DIR COOKIE_DOMAIN ADMIN_PASSWORD LDAP_PASSWORD CONF_SOURCE_DIR PWD_FILE OPENAM_STATS_MODE

# 2. Process configuration files templates

echo ""
echo "Process configuration files templates"
process_templates_dir ${TEMPLATES_DIR} ${CONF_SOURCE_DIR}
echo "Templates processed"
echo ""


# 3. Check that user/group exists and create if it does not

echo "Check group exists: $GROUP"
getent group $GROUP > /dev/null || groupadd -r $GROUP
echo "Check user exists: $USER"
getent passwd $USER > /dev/null || useradd -r  -c "auth-server system user" -d /usr/local/lib/auth-server -g $GROUP $USER
echo "Check configuration dir exists"
mkdir -p ${CONF_DIR}
echo "Create installation directory ${INSTALL_DIR}"
mkdir -p ${INSTALL_DIR}


# 4. Extract Apache Tomcat and cleanup webapps directory

echo ""
WEBAPP_DIR=${INSTALL_DIR}/webapps/auth-server
echo "Extract Apache Tomcat into ${INSTALL_DIR}"
tar --extract --file=${TOMCAT_DISTR} --strip-components=1 --directory=${INSTALL_DIR}
echo "Cleanup existing web applications"
rm -Rf ${INSTALL_DIR}/webapps/*
mkdir ${INSTALL_DIR}/webapps/ROOT

# 5. Deploy OpenAM into Tomcat ROOT

echo "Deploy OpenAM war file into tomcat webapps dir"

mkdir ${WEBAPP_DIR}
cp ${OPENAM_DISTR} ${WEBAPP_DIR}/auth-server.war
cd ${WEBAPP_DIR} && jar -xf auth-server.war && rm -f auth-server.war
cd ${BASE_DIR}

echo "Override configuration files"
cp ${CONF_SOURCE_DIR}/bootstrap.properties ${WEBAPP_DIR}/WEB-INF/classes/
cp ${CONF_SOURCE_DIR}/serverdefaults.properties ${WEBAPP_DIR}/WEB-INF/classes/



# 6. Register Apache Tomcat as ${SERVICE_NAME} system service

echo "Register ${SERVICE_NAME} service"
cp ${BASE_DIR}/scripts/openam/service.sh /etc/init.d/${SERVICE_NAME}
chmod 755 /etc/init.d/${SERVICE_NAME}
chkconfig --add ${SERVICE_NAME}
chkconfig ${SERVICE_NAME} on

echo "Create configuration file: ${CONF_FILE}"
cp ${CONF_SOURCE_DIR}/openam-service.cfg ${CONF_FILE}



# 7. Extract configuration and administration tools

echo "Installing configuration and administration tools"

mkdir -p ${INSTALL_DIR}/configuratortools
tempdir=`mktemp -d`
unzip -q "${OPENAM_CONFIG_TOOLS}" -d "${tempdir}"
mv ${tempdir}/* ${INSTALL_DIR}/configuratortools
rm -Rf $tempdir

mkdir -p ${INSTALL_DIR}/admintools
tempdir=`mktemp -d`
unzip -q "${OPENAM_ADMIN_TOOLS}" -d "${tempdir}"
mv ${tempdir}/* ${INSTALL_DIR}/admintools
rm -Rf $tempdir


# 8. Configure  OpenAM using configuratortools: General Settings, Config store, User Store etc...

echo "Change owner of installation directory to $USER:$GROUP"
chown -R ${USER}:${GROUP} ${INSTALL_DIR}
echo "Starting ${SERVICE_NAME} service"
service ${SERVICE_NAME} start
echo "Waiting 15 seconds to let OpenAM start"
sleep 15
echo "Apply initial configuration using configuratortools."
CMD_RES=$(${JAVA_HOME}/bin/java -jar ${INSTALL_DIR}/configuratortools/openam-configurator-tool-${OPENAM_VERSION}.jar -f ${CONF_SOURCE_DIR}/openam-config.cfg)
if [ "${CMD_RES}" == "Configuration failed!" ]
    then
         echo "Error at configuring OpenAM: ${CMD_RES}"
         echo "The cause could be: 1) Incorrect LDAP password, 2) Invalid configuration, 3) Previously installed version was not uninstalled properly"
         exit 1;
fi


# 9. Setup OpenAM Administration Tools

echo ""
echo "Set up OpenAM Administration Tools"
cd ${INSTALL_DIR}/admintools
./setup -p ${INSTALL_DIR}/work/openamconf
cd ${BASE_DIR}
echo ""


# 10. Configure OpenAM .

echo "Configure OpenAM"
export ADMIN_PASSWORD
. ${BASE_DIR}/scripts/openam/batch-configure.sh
echo "OpenAM was successfully configured"

echo "Change owner of installation directory to $USER:$GROUP"
chown -R $USER:$GROUP $INSTALL_DIR



echo ""
echo ""
echo "  Package OpenAM was successfully installed"
echo ""
echo ""