#!/bin/bash

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
    echo "[WARN]/opt/tyk-sink/tyk_sink.conf is present but SBX_MDCB_LICENSE is not defined."
  fi
fi

# setup another redis
mkdir -p /var/lib/redis2
chown redis:redis /var/lib/redis2
cp /assets/redis-for-remote-gw.conf /etc

# setup slave gateway
if [[ -f /assets/tyk.conf-rpc ]]; then
	cp -f /assets/tyk.conf-rpc /opt/tyk-gateway
	SBX_ORG_ID=$(awk '/Org ID:/ {print $NF}' /initial_credentials.txt)
	SBX_ADMIN_API_KEY=$(awk '/Initial admin key:/ {print $NF}' /initial_credentials.txt)
	sed -i "s/SBX_ORG_ID/$SBX_ORG_ID/g" /opt/tyk-gateway/tyk.conf-rpc
	sed -i "s/SBX_ADMIN_API_KEY/$SBX_ADMIN_API_KEY/g" /opt/tyk-gateway/tyk.conf-rpc
fi

# enable hybrid mode in all orgs
/scripts/enable-hybrid.sh

# dashboard needs to restart to get the updated org
restart dashboard

# now start mdcb
start mdcb
