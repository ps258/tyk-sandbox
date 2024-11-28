#!/bin/bash

# script to start gateway. 
# Can take a single parameter which is the config file to use
# finds the port in the config file and uses that to check if it is already in use

PATH=/scripts:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:$PATH

# always run from /opt/tyk-gateway since so many customers do and assume it
cd /opt/tyk-gateway

command=/opt/tyk-gateway/tyk
TRUE=0
FALSE=1
PID=

function isRunning {
  # check if there's a process listening on the expected port
  # also populates $PID
  PID=$(ss -lnptuH  "( sport = :$PORT )" | awk '/pid=/ {print $NF}' | cut -d, -f 2 | cut -d= -f 2 | sort -u)
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
  PORT=$(jq -r .listen_port $conf)
  log=/var/log/tyk-gateway-$PORT.log
else
  conf=/opt/tyk-gateway/tyk.conf
  PORT=$(awk '/"listen_port"/ {print $NF}' $conf | cut -d: -f2 | sed -e 's/,//')
  log=/var/log/tyk-gateway.log
fi
ci $conf

# refuse to start if its already running
if isRunning
then
  echo "[FATAL]$command already running on port $PORT. Not starting. PID=$PID";
  exit 1
fi

# startup
$command --conf $conf &>> $log &
err=$?
sleep 1

# check if its running
if isRunning
then
  echo "[INFO]'$command --conf $conf' started. PID=$PID. Logs are in $log"
  exit 0
else  
  echo "[FATAL]'$command --conf $conf' didn't start"
  echo "[FATAL]Check $log for errors"
  exit 1
fi
