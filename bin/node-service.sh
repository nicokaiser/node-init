#!/bin/sh

PATH=$PATH:/opt/nodejs/v0.10/bin
LOGFILE=/var/log/node-service.log
ERRFILE=/var/log/node-service.err

while [ 1 ]; do
	echo "Restarting"
	sleep 2
	ulimit -n 32767
	NODE_ENV=production node $(dirname $0)/../server.js >>$LOGFILE 2>>$ERRFILE </dev/null &
	CHILD="$!"
	# avoid the node process to stay running after this script is terminated
	trap "kill $CHILD; exit" exit INT TERM
	wait
done
