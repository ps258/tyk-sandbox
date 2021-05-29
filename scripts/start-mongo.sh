#!/bin/bash

PATH=/scripts:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:$PATH

command=/usr/bin/mongod
conf=/etc/mongod.conf
log=/var/log/mongod.log

# refuse to start if its already running
if pgrep -x $(basename $command) > /dev/null
then
  echo "[FATAL]$command running. Not starting another";
  exit 1
fi

# startup
if [[ ! -d /data/db ]]
then
  mkdir -p /data/db
fi
#$command --config $conf --fork --logpath /var/log/mongod.log --smallfiles
$command --config $conf --noprealloc --fork --logpath /var/log/mongod.log
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
