#!/bin/bash

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

echo "Image starting: $1"

if [[ ! -f /initialised ]]
then
  echo "[INFO]Setting gateway host and port in tyk_analytics.conf"
  sed -i "s/TYK_GW_PORT/$TYK_GW_PORT/g" /opt/tyk-dashboard/tyk_analytics.conf
  sed -i "s/TYK_GW_HOST/$TYK_GW_HOST/g" /opt/tyk-dashboard/tyk_analytics.conf
  echo "[INFO]Generating tyk private keys"
  openssl genrsa -out /privkey.pem 2048
  openssl rsa -in /privkey.pem -pubout -out /pubkey.pem
  if [[ ! -e /opt/tyk-certificates/dashboard-certificate.pem ]]
  then
    echo "[INFO]Creating certificate for the dashboard and gateway"
    openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes -keyout /opt/tyk-certificates/dashboard-key.pem -out /opt/tyk-certificates/dashboard-certificate.pem -subj '/emailAddress=ps258@hotmail.com/C=GB/ST=Mid Lothian/L=Home Office/O=Garage/OU=Desk/CN=example.com'
    ln -s /opt/tyk-certificates/dashboard-certificate.pem /opt/tyk-certificates/gateway-certificate.pem
    ln -s /opt/tyk-certificates/dashboard-key.pem /opt/tyk-certificates/gateway-key.pem
  fi
fi

echo "[INFO]Starting Redis"
/usr/bin/redis-server /etc/redis.conf --daemonize yes

echo "[INFO]Starting mongoDB"
/usr/bin/mongod --fork --logpath /var/log/mongod.log --smallfiles

echo "[INFO]Starting Tyk dashboard"
cd /opt/tyk-dashboard/
/opt/tyk-dashboard/tyk-analytics --conf /opt/tyk-dashboard/tyk_analytics.conf >> /var/log/tyk_dashboard.log 2>&1 &
sleep 5

# once the dashboard is running, use the admin API to create users and upload a licence
if [[ ! -f /initialised ]]
then
  echo "[INFO]Initialising the dashboard"
  /scripts/init-dashboard.sh
fi

echo "[INFO]Starting Tyk gateway"
cd /opt/tyk-gateway/
/opt/tyk-gateway/tyk --conf /opt/tyk-gateway/tyk.conf >> /var/log/tyk_gateway.log 2>&1 &

echo "[INFO]Starting Tyk pump"
cd /opt/tyk-pump/
/opt/tyk-pump/tyk-pump --conf /opt/tyk-pump/pump.conf >> /var/log/tyk_pump.log 2>&1 &

echo "[INFO]Starting Tyk identity broker"
cd /opt/tyk-identity-broker/
/opt/tyk-identity-broker/tyk-identity-broker -c /opt/tyk-identity-broker/tib.conf >> /var/log/tyk_identity_broker.log 2>&1 &

cd /
echo "[INFO]Sandbox instance has started"
sleep 5
tail -f /var/log/tyk_gateway.log
