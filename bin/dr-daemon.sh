#!/bin/sh -e
#
# start/stop dr-trainer daemons
#
### BEGIN INIT INFO
# Provides:          dr-trainer
# Required-Start:    $network $remote_fs
# Required-Stop:     $network $remote_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: DeepRacer Trainer
### END INIT INFO

PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
NAME=dr-trainer
DAEMON=/home/ubuntu/dr-trainer
PIDDIR=/var/run
DESC="DeepRacer Trainer"
USERID=ubuntu

. /lib/lsb/init-functions

check_root() {
  if [ "$(id -u)" != "0" ]; then
    log_failure_msg "You must be root to start, stop or restart $NAME."
    exit 4
  fi
}

###################################################################################################
case "$1" in
start)
  check_root
  exitval=0
  log_daemon_msg "Starting $DESC "
  if pidofproc -p $PIDDIR/$NAME.pid $DAEMON >/dev/null; then
    log_progress_msg "$NAME apparently already running"
    log_end_msg 0
    exit 0
  fi
  start-stop-daemon --start --quiet --oknodo --pidfile $PIDDIR/$NAME.pid \
    --chuid $USERID:$USERID --exec $DAEMON --background --make-pidfile
  log_progress_msg $NAME
  # start my service
  exitval=$?
  log_end_msg $exitval
  ;;
stop)
  check_root
  exitval=0
  log_daemon_msg "Stopping $NAME"
  log_progress_msg $NAME
  # stop my service
  if pidofproc -p $PIDDIR/$NAME.pid $DAEMON >/dev/null; then
    start-stop-daemon --stop --verbose --oknodo --pidfile $PIDDIR/$NAME.pid \
      --exec $DAEMON
    exitval=$?
  else
    log_progress_msg "apparently not running"
  fi
  exitval=$?
  log_end_msg $exitval
  ;;
restart | force-reload)
  check_root
  $0 stop
  # Wait for things to settle down
  sleep 1
  $0 start
  ;;
reload)
  log_warning_msg "Reloading $NAME daemon: not implemented, as the daemon"
  log_warning_msg "cannot re-read the config file (use restart)."
  ;;
status)
  log_warning_msg "Status check $NAME daemon: not implemented, as the daemon"
  ;;
*)
  N=/etc/init.d/$NAME
  echo "Usage: $N {start|stop|restart|force-reload|status}" >&2
  exit 1
  ;;
esac

exit 0
