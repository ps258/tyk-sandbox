#!/bin/bash

PATH=/scripts:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:$PATH

process=tyk-identity-broker
count=0

if [[ ! -d /opt/tyk-identity-broker/ ]]
then
  echo "TIB not installed"
  exit 0
fi

while pgrep -f $process > /dev/null
do
  if [[ $(( count % 5 )) == 0 ]]
  then
    echo "[INFO]Killing $process"
    pkill -f $process
  fi
  if [[ $count -gt 1 && $(( count % 24 )) == 0 ]]
  then
    echo "[FATAL]$process still running. Unable to kill. Investigate"
    exit 1
  fi
  sleep 1
  count=$(( count + 1 ))
done
if [[ $count -eq 0 ]]
then
  echo "[INFO]$process not running. Nothing to kill"
fi
