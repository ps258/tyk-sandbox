#!/bin/bash

# script to start redis. 
# Can take a single parameter which is the config file to use
# finds the port in the config file and uses that to check if it is already in use

PATH=/scripts:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:$PATH

command=/usr/bin/redis-server
TRUE=0
FALSE=1
PID=

function isRunning {
  # check if there's a process listening on the expected port
	# also populates $PID
  PID=$(ss -lnptu4H  "( sport = :$PORT )" | awk '/pid=/ {print $NF}' | cut -d, -f 2 | cut -d= -f 2)
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

# refuse to start if its already running

if isRunning
then
  echo "[FATAL]$command already running on port $PORT. Not starting. PID=$PID";
  exit 1
fi

# startup
mkdir -p /var/lib/redis/
ci "$conf"
$command "$conf" --daemonize yes

# check if its running
if isRunning
then
  echo "[INFO]'$command "$conf" --daemonize yes' started. PID=$PID"
  exit 0
else  
  echo "[FATAL]'$command "$conf" --daemonize yes' didn't start"
  exit 1
fi
