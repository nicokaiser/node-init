#!/bin/sh

PATH=$PATH:/opt/nodejs/v0.4/bin
LOGFILE=/var/log/node-service.log

while [ 1 ]; do
	echo "Restarting"
	ulimit -n 32767
	NODE_ENV=production node /var/www/node.example.com/current/server.js >/dev/null 2>>$LOGFILE </dev/null &
	CHILD="$!"
	# avoid the node process to stay running after this script is terminated
	trap "kill $CHILD; exit" exit INT TERM
	wait
done
