#!/bin/bash

PATH=/scripts:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:$PATH

command=/opt/tyk-identity-broker/tyk-identity-broker
conf=/opt/tyk-identity-broker/tib.conf
log=/var/log/tyk-identity-broker.log

if [[ ! -e $command ]]
then
  echo "TIB not installed in $command"
  exit 0
fi
ci $conf

# refuse to start if its already running
if pgrep -f $(basename $command) > /dev/null
then
  echo "[FATAL]$command running. Not starting another";
  exit 1
fi

# startup
$command -c $conf &>> $log &
err=$?
sleep 1

# check if its running
if ! pgrep -f $(basename $command) > /dev/null
then
  echo "[FATAL]$command exited with $err and didn't start" 1>&2
  echo "[FATAL]Check $log for errors" 1>&2
  exit 1
else
  echo "[INFO]$command started"
fi
