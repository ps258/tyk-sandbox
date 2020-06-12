#!/bin/bash

echo "Image starting: $1"

if [[ ! -f /initialised ]]
then
  echo "[INFO]Setting gateway port in tyk_analytics.conf"
  set -i "s/TYK_API_PORT/$TYK_API_PORT/g" /opt/tyk-dashboard/tyk_analytics.conf
fi

echo "[INFO]Starting Redis"
/usr/bin/redis-server /etc/redis.conf --daemonize yes

echo "[INFO]Starting mongoDB"
/usr/bin/mongod --fork --logpath /var/log/mongod.log --smallfiles

echo "[INFO]Starting Tyk dashboard"
/opt/tyk-dashboard/tyk-analytics --conf /opt/tyk-dashboard/tyk_analytics.conf >> /var/log/tyk_dashboard.log 2>&1 &
sleep 5

if [[ ! -f /initialised ]]
then
  echo "[INFO]Initialising the dashboard"
  /scripts/init-dashboard.sh
fi

echo "[INFO]Starting Tyk gateway"
/opt/tyk-gateway/tyk --conf /opt/tyk-gateway/tyk.conf >> /var/log/tyk_gateway.log 2>&1 &

echo "[INFO]Starting Tyk pump"
/opt/tyk-pump/tyk-pump --conf /opt/tyk-pump/pump.conf >> /var/log/tyk_pump.log 2>&1 &

echo "[INFO]Starting Tyk identity broker"
/opt/tyk-identity-broker/tyk-identity-broker --conf /opt/tyk-tyk-identity-broker/tib.conf >> /var/log/tyk_identity_broker.log 2>&1 &

echo "[INFO]Sandbox instance has started"
sleep 5
tail -f /var/log/tyk_gateway.log
