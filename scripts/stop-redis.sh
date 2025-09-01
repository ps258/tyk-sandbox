#!/bin/bash

# script to stop redis. 
# Can take a single parameter which is the config file to use
# finds the port in the config file and uses that to check if it is already in use

PATH=/scripts:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:$PATH

TRUE=0
FALSE=1
PID=
count=0
maxWait=11

function isRunning {
  # check if there's a process listening on the expected port
	# also populates $PID
  if [[ -f /usr/sbin/ss ]]; then
    PID=$(ss -lnptuH  "( sport = :$PORT )" | awk '/pid=/ {print $NF}' | cut -d, -f 2 | cut -d= -f 2 | sort -u)
  else
    PID=$(netstat -lptuna | grep LISTEN | awk '$4 ~ ":'$PORT'" {print $7}' | cut -d/ -f1)
  fi
  if [[ ! -z $PID ]]
  then
    return $TRUE
  else
    return $FALSE
  fi
}

if [[ $# > 0 ]]; then
  conf="$1"
  if [[ ! -f "$conf" ]]; then
    echo "[FATAL]Config file not found '$conf'"
    exit 1
  fi
else
  conf=/etc/redis.conf
fi

PORT=$(awk '/^port/ {print $NF}' "$conf")

while isRunning
do
  if [[ $(( count % 5 )) == 0 ]]
  then
    echo "[INFO]Killing $PID listening on port $PORT"
    kill $PID
  fi
  if [[ $count -gt 1 && $(( count % $maxWait )) == 0 ]]
  then
    echo "[FATAL]$PID still running after ${maxWait}s. Unable to kill. Investigate"
    exit 1
  fi
  sleep 1
  count=$(( count + 1 ))
done
if [[ $count -eq 0 ]]
then
  echo "[INFO]Nothing listening on port $PORT. Nothing to kill"
fi
