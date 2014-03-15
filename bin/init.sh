#!/bin/sh

### BEGIN INIT INFO
# Provides:          node-service
# Required-Start:    $local_fs $remote_fs $network $syslog $mail-transport-agent
# Required-Stop:     $local_fs $remote_fs $network $syslog $mail-transport-agent
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start/stop node-service
### END INIT INFO

DESC="node.js service"
DAEMON_USER=www-data
DAEMON=/bin/sh
DAEMON_ARGS=$(dirname $(readlink -f $0))/node-service.sh
PIDFILE=/var/run/node-service.pid

. /lib/init/vars.sh
. /lib/lsb/init-functions

do_start()
{
    # To allow many connections
    ulimit -n 32767
    
    # TCP tweaks
    sysctl -q -w net.ipv4.tcp_retries2=5 # 15
    sysctl -q -w net.ipv4.tcp_keepalive_time=300 # 7200
    sysctl -q -w net.ipv4.tcp_keepalive_probes=2 # 9
    sysctl -q -w net.ipv4.tcp_keepalive_intvl=5 # 75

    # Wait to make sure network is there
    sleep 1

    # Redirect privileged ports
    iptables -t nat -I PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 10080
    
    start-stop-daemon --start --quiet --pidfile $PIDFILE --chuid $DAEMON_USER --background --exec $DAEMON --test > /dev/null \
      || { log_daemon_msg "already running"; return 1; }
    start-stop-daemon --start --quiet --chuid $DAEMON_USER --make-pidfile --pidfile $PIDFILE --background --exec $DAEMON -- $DAEMON_ARGS \
      || { log_daemon_msg "could not be started"; return 2; }
    log_daemon_msg "started"
}

do_stop()
{
    start-stop-daemon --stop --quiet --retry=TERM/30/KILL/5 --pidfile $PIDFILE --chuid $DAEMON_USER --exec $DAEMON
    RETVAL="$?"
    [ "$RETVAL" = 2 ] && return 2    
    start-stop-daemon --stop --quiet --oknodo --retry=0/3/KILL/5 --pidfile $PIDFILE --chuid $DAEMON_USER --exec $DAEMON -- $DAEMON_ARGS
    [ "$?" = 2 ] && return 2
    rm -f $PIDFILE
    [ "$RETVAL" = 1 ] && log_daemon_msg "not running"
    [ "$RETVAL" = 0 ] && log_daemon_msg "stopped"
    return "$RETVAL"
}

do_status()
{
  RUNNING=$(running)
  ispidactive=$(pidof $DAEMON | grep `cat $PIDFILE 2>&1` >/dev/null 2>&1)
  ISPIDACTIVE=$?
  if [ -n "$RUNNING" ]; then
    if [ $ISPIDACTIVE ]; then
      log_success_msg "$DESC is running"
      exit 0
    fi
  else
    if [ -f $PIDFILE ]; then
      log_success_msg "$DESC is NOT running, phantom pidfile $PIDFILE"
      exit 1
    else
      log_success_msg "$DESC is NOT running"
      exit 3
    fi
  fi
}

running()
{
  RUNSTAT=$(start-stop-daemon --quiet --start --pidfile $PIDFILE --chuid $DAEMON_USER --background --exec $DAEMON --test > /dev/null)
  if [ "$?" = 1 ]; then
    echo y
  fi
}

case "$1" in
  start)
    log_daemon_msg "Starting $DESC"
    do_start
    case "$?" in 
      0|1) log_end_msg 0 ;;
      2) log_end_msg 1 ;;
    esac
    ;;   
  stop)
    log_daemon_msg "Stopping $DESC"
    do_stop
    case "$?" in 
      0|1) log_end_msg 0 ;;
      2) log_end_msg 1 ;;
    esac
    ;;
  restart)
    log_daemon_msg "Restarting $DESC"
    do_stop
    case "$?" in
      0|1)
        do_start
        case "$?" in
          0) log_end_msg 0 ;;
          1) log_end_msg 1 ;; # Old process is still running
          *) log_end_msg 1 ;; # Failed to start
        esac
        ;;
      *)
        log_end_msg 1
        ;;
    esac
    ;;
  status)
    do_status
    ;;
  *)
    echo "Usage: $0 (start|stop|restart|status)" >&2
    exit 3
    ;;
esac

exit 0
