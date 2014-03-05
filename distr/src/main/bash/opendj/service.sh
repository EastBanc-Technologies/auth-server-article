#!/bin/bash
#
# opendj
#
# chkconfig: 345 95 5
# description: Control the OpenDJ Directory Server

source /etc/auth-server/opendj.cfg
export INSTALL_ROOT

cd ${INSTALL_ROOT}

RETVAL=0
start(){
   echo "Starting OpenDJ ..."
   su $USER -c "${INSTALL_ROOT}/bin/start-ds --quiet"
   RETVAL=$?
   echo
   [ $RETVAL -eq 0 ] && touch $LOCKFILE
   return $RETVAL
}

stop(){
   echo "Shutting down OpenDJ ... "
   su $USER -c "${INSTALL_ROOT}/bin/stop-ds --quiet"
   RETVAL=$?
   echo
   [ $RETVAL -eq 0 ] && rm -f $LOCKFILE
   return $RETVAL
}


case "${1}" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  restart)
    stop
    start
    ;;
  status)
    su $USER -c "${INSTALL_ROOT}/bin/status"
    ;;
  *)
    echo $"Usage: $0 {start|stop|restart|status}"
    exit 1
  ;;
esac