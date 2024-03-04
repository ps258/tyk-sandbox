#!/bin/bash

PATH=/scripts:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:$PATH

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

	if [[ ! -e /privkey.pem ]]; then
		echo "[INFO]Generating tyk private keys to secure traffic between the dashboard and the management gateway"
		openssl genrsa -out /privkey.pem 2048
		openssl rsa -in /privkey.pem -pubout -out /pubkey.pem
	fi

	# create a local cert if one isn't already present
	if [[ ! -e /opt/tyk-certificates/gateway-certificate.pem ]]; then
		echo "[INFO]Creating certificate for the dashboard and gateway"
		SAN="DNS:localhost"
		if [[ -n $SBX_GW_CNAME ]]; then
			SAN="DNS:$SBX_GW_CNAME, $SAN"
			SUBJECT="/emailAddress=email@company.com/C=GB/ST=Mid Lothian/L=Home Office/O=Garage/OU=Desk/CN=$SBX_GW_CNAME"
		else
			SUBJECT='/emailAddress=email@company.com/C=GB/ST=Mid Lothian/L=Home Office/O=Garage/OU=Desk/CN=tyk-sandbox.com'
		fi
		if [[ -n $SBX_DSHB_CNAME ]]; then
			SAN="DNS:$SBX_DSHB_CNAME, $SAN"
		fi
		if [[ -n $SBX_PTL_CNAME ]]; then
			SAN="DNS:$SBX_PTL_CNAME, $SAN"
		fi
		openssl genrsa -des3 -passout pass:ABC-123 -out /opt/tyk-certificates/gateway-key.pem 2048
		openssl req -new -key /opt/tyk-certificates/gateway-key.pem -passin pass:ABC-123 -subj "$SUBJECT" -out /opt/tyk-certificates/certificate.csr
		cp /opt/tyk-certificates/gateway-key.pem /opt/tyk-certificates/gateway-key.pem.orig
		openssl rsa -in /opt/tyk-certificates/gateway-key.pem.orig -out /opt/tyk-certificates/gateway-key.pem -passin pass:ABC-123
		rm -f /opt/tyk-certificates/gateway-key.pem.orig
		cat > /opt/tyk-certificates/extfile.ext <<- EOF
		subjectKeyIdentifier   = hash
		authorityKeyIdentifier = keyid:always,issuer:always
		basicConstraints       = CA:TRUE
		keyUsage               = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment, keyAgreement, keyCertSign
		subjectAltName         = $SAN
		issuerAltName          = issuer:copy
		EOF
		openssl x509 -req -in /opt/tyk-certificates/certificate.csr -signkey /opt/tyk-certificates/gateway-key.pem -out /opt/tyk-certificates/gateway-certificate.pem -days 3650 -sha256 -extfile /opt/tyk-certificates/extfile.ext
	fi
fi

# setup hosts table entries at each startup since /etc/hosts seems to be overwritten
if [[ -n $SBX_HOST_ENTRIES ]]; then
	# setup any extra entries in /etc/hosts that are provided via $SBX_HOST_ENTRIES
	# The format is for it is # the format is 'ipaddress:alias:alias,next ipaddress:its alias:its other alias'
	# like this
	# SBX_HOST_ENTRIES=$SBX_HOST_IP_ADDR:httpbin.org:homebin.org,$SBX_DSHB_HOST:dbhost.home:anotherhost.home
	# this entry would go in your ~/.tyk-sandbox
	# Note that $SBX_HOST_IP_ADDR will be the IP address of the host running the sandbox not the ip address of the sandbox itself
	echo "### added during setup $0 ###" >> /etc/hosts
	for line in $(eval echo $SBX_HOST_ENTRIES | sed 's/,/ /g'); do  echo $line | sed 's/:/ /g' | \
		while read address names; do
			echo $address $names >> /etc/hosts
		done
	done
fi

echo "[INFO]Starting plugin server"
/scripts/serve-plugins.sh >> /var/log/plugin-server.log 2>&1 &

echo "[INFO]Starting Redis"
start redis

if [[ -z $SBX_MODE || $SBX_MODE != 'CE' ]]; then
	echo "[INFO]Starting mongoDB"
	start mongo

	echo "[INFO]Starting Tyk dashboard"
	start dashboard
	sleep 1

	# once the dashboard is running, use the admin API to create users and upload a licence
	if [[ ! -f /initialised ]]; then
		echo "[INFO]Initialising the dashboard"
		/scripts/init-dashboard.sh > /var/log/init-dashboard.log 2>&1
		if [[ -n $SBX_LICENSE ]] || [[ -n $SBX_USER && -n $SBX_PASSWORD ]]; then
			sleep 1
			restart dashboard
			sleep 1
		fi
	fi

  echo "[INFO]Starting Tyk pump"
  start pump

  if [[ -d /opt/tyk-identity-broker/ ]]; then
    echo "[INFO]Starting Tyk identity broker"
    start tib
  fi

elif [[ $SBX_MODE = 'CE' ]]; then
	# setup CE
	if [[ ! -f /initialised ]]; then
		rm -f /opt/tyk-gateway/apps/* /opt/tyk-gateway/policies/*
		cp -f /assets/tyk-CE.conf /opt/tyk-gateway/tyk.conf
	fi
  # create an empyt file so "sbctl info" doesn't give errors
  touch /initial_credentials.txt
fi

if [[ -d /opt/tyk-sink ]]; then
	echo "[INFO]Starting MDCB"
	start mdcb
fi

echo "[INFO]Starting Tyk gateway"
start gateway

#echo "[INFO]Capping analytics collections"
#/scripts/cap-mongo-z_collections.sh

cd /
echo "[INFO]Sandbox instance has started"
sleep infinity
