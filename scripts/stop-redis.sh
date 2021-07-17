#!/bin/bash

PATH=/scripts:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:$PATH

process=redis-server
count=0
maxWait=11

while pgrep -x $process > /dev/null
do
  if [[ $(( count % 5 )) == 0 ]]
  then
    echo "[INFO]Killing $process"
    pkill -x $process
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
