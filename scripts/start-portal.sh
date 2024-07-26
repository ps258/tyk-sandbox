#!/bin/bash

PATH=/scripts:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:$PATH

PORTAL_LOG_LEVEL=$TYK_LOGLEVEL
export PORTAL_LOG_LEVEL

command=/opt/portal/dev-portal
conf=/opt/portal/portal.conf
log=/var/log/tyk-portal.log
ci $conf

# refuse to start if its already running
if pgrep -x $(basename $command) > /dev/null
then
  echo "[FATAL]$command running. Not starting another";
  exit 1
fi

# startup
cd /opt/portal
$command -bootstrap -first Tyk -last Admin -user $SBX_USER -pass $(echo $SBX_PASSWORD | base64 -d) --conf $conf &>> $log &
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
