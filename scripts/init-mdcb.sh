#!/bin/bash

# script to enable and start MDCB and an edge gateway

PATH=/scripts:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:$PATH

if [[ -d /opt/tyk-sink ]]; then
	echo "[FATAL]tyk-sink already installed"
	exit 1
fi

if [[ $# -lt 1 ]]; then
	echo "Usage: $0 <tyk-sink-rpm-path>"
	exit 1
fi

if [[ ! -f $1 ]]; then
	echo "Usage: $0 <tyk-sink-rpm-path>"
	exit 1
fi

rpm --install $1

# setup MDCB config 
cp -f /assets/tyk_sink.conf /opt/tyk-sink/
if [[ -f /opt/tyk-sink/tyk_sink.conf ]]; then
  if [[ -n $SBX_MDCB_LICENSE ]]; then
    sed -i "s/SBX_MDCB_LICENSE/$SBX_MDCB_LICENSE/g" /opt/tyk-sink/tyk_sink.conf
  else
    echo "[WARN]/opt/tyk-sink/tyk_sink.conf is present but SBX_MDCB_LICENSE is not defined. Manually edit /opt/tyk-sink/tyk_sink.conf and restart mdcb"
  fi
fi

# setup another redis
echo "[INFO]Configuring edge redis on port 6380"
mkdir -p /var/lib/redis2
chown redis:redis /var/lib/redis2
cp /assets/redis-for-remote-gw.conf /etc

# load the SBX_ORG_ID and SBX_ADMIN_API_KEY from where they were saved during initialisation of the sandbox
. /initial_credentials.txt

# setup slave gateway
echo "[INFO]Configuring Edge gateway"
if [[ -f /assets/tyk.conf-rpc ]]; then
	cp -f /assets/tyk.conf-rpc /opt/tyk-gateway
	#SBX_ORG_ID=$(awk '/Org ID:/ {print $NF}' /initial_credentials.txt)
	#SBX_ADMIN_API_KEY=$(awk '/Initial admin key:/ {print $NF}' /initial_credentials.txt)
	sed -i "s/SBX_ORG_ID/$SBX_ORG_ID/g" /opt/tyk-gateway/tyk.conf-rpc
	sed -i "s/SBX_ADMIN_API_KEY/$SBX_ADMIN_API_KEY/g" /opt/tyk-gateway/tyk.conf-rpc
fi

# enable hybrid mode in all orgs
echo "[INFO]Enabling hybrid mode in all Orgs"
/scripts/enable-hybrid.sh

# switch current gateway to port 8081 and allow edge gateway to be on port 8080 so that it's the default gateway
stop dashboard gateway
sed -i "s/8080/8081/g" /opt/tyk-dashboard/tyk_analytics.conf /opt/tyk-gateway/tyk.conf

# switch the current dashboard to connect to the management gateway on port 8081

# dashboard needs to restart to get the updated org and the new management gateway
echo "[INFO]Restarting dashboard and gateway to apply organisation and gateway port changes"
start dashboard gateway

# now start mdcb
echo "[INFO]Starting MDCB"
start mdcb