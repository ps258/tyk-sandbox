#!/bin/bash

PATH=/scripts:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:$PATH
# This script starts the whole MDCB subsystem

# start tyk-sink first
/scripts/start-sink.sh

# next edge redis
/scripts/start-redis.sh /etc/redis-for-remote-gw.conf

# lastly edge gateway
/scripts/start-gateway.sh /opt/tyk-gateway/tyk.conf-rpc