#!/bin/bash
#
# openam
#
# chkconfig: 345 95 5
# description: OpenAM service
source /etc/auth-server/openam.cfg
SHUTDOWN_WAIT=10
CATALINA_PID=$CATALINA_HOME/openam.pid
export JAVA_OPTS CATALINA_HOME CATALINA_PID


RETVAL=0
start(){
   echo "Starting OpenAM: "
   su $USER -c "${CATALINA_HOME}/bin/startup.sh"
   RETVAL=$?
   echo
   return $RETVAL
}

stop(){
   echo "Shutting down OpenAM..."
   if [ -f ${CATALINA_PID} ]; then
        pid=$(<$CATALINA_PID)
        if [ `ps -p $pid | grep -c $pid` = '1' ]; then
            su $USER -c $CATALINA_HOME/bin/shutdown.sh
            let kwait=$SHUTDOWN_WAIT
            count=0;
            until [ `ps -p $pid | grep -c $pid` = '0' ] || [ $count -gt $kwait ]
            do
                echo "waiting for processes to exit";
                sleep 1
                let count=$count+1;
            done
            if [ $count -gt $kwait ]; then
                echo "killing processes which didn't stop after $SHUTDOWN_WAIT seconds"
                kill -9 $pid
                echo "process killed"
            fi
            rm -f ${CATALINA_PID}
        else
            echo "OpenAM is stopped"
        fi
   else
        echo "OpenAM is stopped"
   fi
   return 0
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
    if [ -f ${CATALINA_PID} ]; then
       pid=$(<$CATALINA_PID)
       if [ `ps -p $pid | grep -c $pid` = '1' ]; then
            echo "OpenAM is running with pid: $pid"
            exit 0
       fi
    fi
    echo "OpenAM is stopped"
    ;;
  *)
    echo $"Usage: $0 {start|stop|restart|status}"
    exit 1
  ;;
esac