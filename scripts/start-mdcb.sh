#!/bin/bash

PATH=/scripts:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:$PATH
# This script starts the whole MDCB subsystem

# start tyk-sink first
/scripts/start-sink.sh

# next redis
/usr/bin/redis-server /etc/redis-for-remote-gw.conf --daemonize yes
sleep 1

# lastly gateway

command=/opt/tyk-gateway/tyk
conf=/opt/tyk-gateway/tyk.conf-rpc
log=/var/log/tyk-gateway-rpc.log
ci $conf
flags=""

# startup
$command --conf $conf $flags &>> $log &
err=$?
sleep 1

echo "[INFO]$command started"
