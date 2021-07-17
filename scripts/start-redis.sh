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
mkdir -p /var/lib/redis/
conf=/etc/redis.conf
$command $conf --daemonize yes

# check if its running
if [[ $(pgrep -x $(basename $command) | wc -l) -lt 1 ]]
then
  echo "[FATAL]$(basename $command) didn't start"
  exit 1
else
  echo "[INFO]$(basename $command) started"
fi
