#!/bin/bash

PATH=/scripts:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:$PATH

command=/opt/tyk-dashboard/tyk-analytics
conf=/opt/tyk-dashboard/tyk_analytics.conf
log=/var/log/tyk_dashboard.log

# refuse to start if its already running
if pgrep -x $(basename $command) > /dev/null
then
  echo "[FATAL]$command running. Not starting another";
  exit 1
fi

# startup
$command --conf $conf &>> $log &
err=$?
sleep 1

# check if its running
if ! pgrep -x $(basename $command) > /dev/null
then
  echo "[FATAL]$command exited with $err and didn't start" 1>&2
  echo "[FATAL]Check $log for errors" 1>&2
  exit 1
else
  echo "[INFO]$command started"
fi
