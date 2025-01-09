#!/bin/bash

PATH=/scripts:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:$PATH

command=/opt/tyk-identity-broker/tyk-identity-broker
process=tyk-identity-broker
count=0
maxWait=11

if [[ ! -e $command ]]
then
  echo "TIB not installed in $command"
  exit 0
fi

while pgrep -f $process > /dev/null
do
  if [[ $(( count % 5 )) == 0 ]]
  then
    echo "[INFO]Killing $process"
    pkill -f $process
  fi
  if [[ $count -gt 1 && $(( count % $maxWait )) == 0 ]]
  then
    echo "[FATAL]$process still running after ${maxWait}s. Unable to kill. Investigate"
    exit 1
  fi
  sleep 1
  count=$(( count + 1 ))
done
if [[ $count -eq 0 ]]
then
  echo "[INFO]$process not running. Nothing to kill"
fi
