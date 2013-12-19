#!/bin/bash
#
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Starts a accumulo thrift poxy
#
# chkconfig: 2345 85 15
# description: accumulo proxy
#
### BEGIN INIT INFO
# Provides:          accumulo-proxy
# Short-Description: Accumulo Thrift Proxy
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Required-Start:    $syslog $remote_fs
# Required-Stop:     $syslog $remote_fs
# Should-Start:
# Should-Stop:
### END INIT INFO

. /lib/lsb/init-functions
if [ -f /etc/default/accumulo ]; then  
  . /etc/default/accumulo
fi

if [ -f /etc/accumulo/conf/accumulo-env.sh ] ; then
  . /etc/accumulo/conf/accumulo-env.sh
fi

RETVAL_SUCCESS=0

STATUS_RUNNING=0
STATUS_DEAD=1
STATUS_DEAD_AND_LOCK=2
STATUS_NOT_RUNNING=3
STATUS_OTHER_ERROR=102

ERROR_PROGRAM_NOT_INSTALLED=5
ERROR_PROGRAM_NOT_CONFIGURED=6

RETVAL=0
SLEEP_TIME=5
PROC_NAME="java"
APP_NAME="proxy"
EXEC_PATH="{{ accumulo_prefix }}/bin/accumulo"
DAEMON="accumulo-proxy"
PIDFILE="/var/run/hadoop/${DAEMON}.pid"
DESC="Accumulo Proxy"
SVC_USER="accumulo"
CONF_FILE="{{ accumulo_config }}/proxy.properties"
LOCKDIR="/var/lock/subsys"
LOGDIR="{{ accumulo_log_root }}"
LOCKFILE="${LOCKDIR}/${DAEMON}"
LOGFILE="${LOGDIR}/${DAEMON}.out"
ERR_LOGFILE="${LOGDIR}/${DAEMON}.err"

[ -d "$LOCKDIR" ] || install -d -m 0755 $LOCKDIR 1>/dev/null 2>&1 || :

start() {
  [ -x $EXEC_PATH ] || exit $ERROR_PROGRAM_NOT_INSTALLED
  [ -d $CONF_DIR ] || exit $ERROR_PROGRAM_NOT_CONFIGURED
  log_success_msg "Starting ${DESC}: "

  su -s /bin/bash $SVC_USER -c "exec nohup $EXEC_PATH proxy -p '$CONF_FILE' 2>$ERR_LOGFILE 1>$LOGFILE &"
  sleep 1
  writepid
  checkstatusofproc
  RETVAL=$?

  [ $RETVAL -eq $RETVAL_SUCCESS ] && touch $LOCKFILE
  return $RETVAL
}

stop() {
  log_success_msg "Stopping ${DESC}: "
  RETVAL=1
  if [ -f $PIDFILE ]
  then
    PID=$(cat $PIDFILE)
    su -s /bin/bash $SVC_USER -c "kill $PID"
    RETVAL=$?
  fi
  [ $RETVAL -eq $RETVAL_SUCCESS ] && rm -f $LOCKFILE $PIDFILE
}

restart() {
  stop
  start
}

writepid(){
  PID_LINE=$(ps --noheader -o pid,args -C java | grep "Dapp=${APP_NAME}" | head -1)
  if [ "$PID_LINE" == "" ]
  then
    RETVAL=''
  else  
    PID=$(echo $PID_LINE | awk '{print $1}')
    su -s /bin/bash $SVC_USER -c "echo $PID > $PIDFILE"
    RETVAL=$?
  fi
  return $RETVAL
}

checkstatusofproc(){
  pidofproc -p $PIDFILE $PROC_NAME > /dev/null
}

checkstatus(){
  checkstatusofproc
  status=$?

  case "$status" in
    $STATUS_RUNNING)
      log_success_msg "${DESC} is running"
      ;;
    $STATUS_DEAD)
      log_failure_msg "${DESC} is dead and pid file exists"
      ;;
    $STATUS_DEAD_AND_LOCK)
      log_failure_msg "${DESC} is dead and lock file exists"
      ;;
    $STATUS_NOT_RUNNING)
      log_failure_msg "${DESC} is not running"
      ;;
    *)
      log_failure_msg "${DESC} status is unknown"
      ;;
  esac
  return $status
}

condrestart(){
  [ -e $LOCKFILE ] && restart || :
}

check_for_root() {
  if [ $(id -ur) -ne 0 ]; then
    echo 'Error: root user required'
    echo
    exit 1
  fi
}

service() {
  case "$1" in
    start)
      check_for_root
      start
      ;;
    stop)
      check_for_root
      stop
      ;;
    status)
      checkstatus
      RETVAL=$?
      ;;
    restart)
      check_for_root
      restart
      ;;
    condrestart|try-restart)
      check_for_root
      condrestart
      ;;
    *)
      echo $"Usage: $0 {start|stop|status|restart|try-restart|condrestart}"
      exit 1
  esac
}

service "$1"

exit $RETVAL
