#!/bin/bash

PATH=/scripts:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:$PATH

unalias cp

echo "Image starting: $1"

if [[ ! -f /initialised ]]; then

  echo "[INFO]Copying the config files into place"
  if [[ -d /opt/tyk-identity-broker ]]; then
    # TIB is installed, we need to use the tib enabled tyk_analytics.conf
    cp -f /assets/tyk_analytics-tib.conf /opt/tyk-dashboard/tyk_analytics.conf
    cp -f /assets/tib.conf /opt/tyk-identity-broker/
  else
    cp -f /assets/tyk_analytics.conf /opt/tyk-dashboard
  fi
  cp -f /assets/tyk.conf /opt/tyk-gateway/
  cp -f /assets/pump.conf /opt/tyk-pump/

	if [[ -n $SBX_GW_CNAME ]]; then
		SBX_GW_HOST=$SBX_GW_CNAME
	fi
	if [[ -n $SBX_DSHB_CNAME ]]; then
		SBX_DSHB_HOST=$SBX_DSHB_CNAME
	fi

  echo "[INFO]Setting gateway host and port in tyk_analytics.conf"
  sed -i "s/SBX_GW_PORT/$SBX_GW_PORT/g" /opt/tyk-dashboard/tyk_analytics.conf
  sed -i "s/SBX_GW_HOST/$SBX_GW_HOST/g" /opt/tyk-dashboard/tyk_analytics.conf
  sed -i "s/SBX_DSHB_HOST/$SBX_DSHB_HOST/g" /opt/tyk-dashboard/tyk_analytics.conf
  sed -i "s/SBX_DSHB_PORT/$SBX_DSHB_PORT/g" /opt/tyk-dashboard/tyk_analytics.conf

  echo "[INFO]Generating tyk private keys"
  openssl genrsa -out /privkey.pem 2048
  openssl rsa -in /privkey.pem -pubout -out /pubkey.pem

	# create a local cert if one isn't already present
  if [[ ! -e /opt/tyk-certificates/dashboard-certificate.pem ]]; then
    echo "[INFO]Creating certificate for the dashboard and gateway"
    openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes -keyout /opt/tyk-certificates/dashboard-key.pem -out /opt/tyk-certificates/dashboard-certificate.pem -subj '/emailAddress=email@company.com/C=GB/ST=Mid Lothian/L=Home Office/O=Garage/OU=Desk/CN=tyk-sandbox.com'
    ln -s /opt/tyk-certificates/dashboard-certificate.pem /opt/tyk-certificates/gateway-certificate.pem
    ln -s /opt/tyk-certificates/dashboard-key.pem /opt/tyk-certificates/gateway-key.pem
  fi
fi

#grep -q $SBX_GW_HOST /etc/hosts || echo "127.0.0.1 $SBX_GW_HOST" >> /etc/hosts

echo "[INFO]Starting plugin server"
/scripts/serve-plugins.sh >> /var/log/plugin-server.log 2>&1 &

echo "[INFO]Starting Redis"
/scripts/start-redis.sh

echo "[INFO]Starting mongoDB"
/scripts/start-mongo.sh

echo "[INFO]Starting Tyk dashboard"
/scripts/start-dashboard.sh
sleep 1

# once the dashboard is running, use the admin API to create users and upload a licence
if [[ ! -f /initialised ]]; then
  echo "[INFO]Initialising the dashboard"
  /scripts/init-dashboard.sh > /var/log/init-dashboard.log 2>&1
	sleep 1
	restart dashboard
	sleep 1
fi

echo "[INFO]Starting Tyk gateway"
/scripts/start-gateway.sh

echo "[INFO]Starting Tyk pump"
/scripts/start-pump.sh

if [[ -d /opt/tyk-identity-broker/ ]]; then
  echo "[INFO]Starting Tyk identity broker"
  /scripts/start-tib.sh
fi

if [[ -d /opt/tyk-sink ]]; then
  echo "[INFO]Starting MDCB"
  start mdcb
fi

cd /
echo "[INFO]Sandbox instance has started"
sleep infinity
