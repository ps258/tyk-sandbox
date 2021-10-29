#!/bin/bash

# if SBX_LICENSE is set, install the licence
# if SBX_USER and SBC_PASSWORD are set, create an admin user with those credentials
# saves the admin key for an admin user into /initial_credentials.txt as well as username and password
# also publishes all APIs from /assets/APIs/*.json if an admin account was created

PATH=/scripts:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:$PATH
PROTOCOL=http

if [[ -n $SBX_LICENSE ]]
then
  echo "[INFO]Adding dashboard license"
  curl -k -s -d "license=$SBX_LICENSE" $PROTOCOL://localhost:3000/license
  echo Initial licence: $SBX_LICENSE >> /initial_credentials.txt
fi

if [[ -n $SBX_USER && -n $SBX_PASSWORD ]]
then
  SBX_CLEAR_PASSWORD=$(echo $SBX_PASSWORD | base64 -d)
  echo "[INFO]Bootstraping default user: $SBX_USER"
  curl -k -s -d "email_address=$SBX_USER&first_name=Tyk&last_name=Admin&password=$SBX_CLEAR_PASSWORD&confirm_password=$SBX_CLEAR_PASSWORD" $PROTOCOL://localhost:3000/bootstrap
  echo Initial admin User: $SBX_USER >> /initial_credentials.txt
  echo Initial admin Password (base64 encoded): $SBX_PASSWORD >> /initial_credentials.txt
	echo Initial admin key: $(admin-auth) >> /initial_credentials.txt
  # publish all apis from /assets/APIs
  /scripts/publish-apis /assets/APIs/*.json
fi
touch /initialised 
