#!/bin/bash

PATH=/scripts:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:$PATH

command=/usr/bin/redis-server

# refuse to start if its already running
if [[ $(pgrep -x $(basename $command) | wc -l) -gt 0 ]]
then
  echo "[FATAL]$command running. Not starting";
  exit 1
fi

# startup
if [[ ! -d /var/lib/redis ]]
then
  mkdir -p /var/lib/redis
fi
$command /etc/redis.conf --daemonize yes

# check if its running
if [[ $(pgrep -x $(basename $command) | wc -l) -lt 1 ]]
then
  echo "[FATAL]One or more $(basename $command) didn't start"
  exit 1
else
  echo "[INFO]$(basename $command) started"
fi
