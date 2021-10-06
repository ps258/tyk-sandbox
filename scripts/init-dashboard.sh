#!/bin/bash

PROTOCOL=http

if [[ -n $SBX_LICENSE ]]
then
  echo "[INFO]Adding dashboard license"
  curl -k -s -d "license=$SBX_LICENSE" -X POST $PROTOCOL://localhost:3000/license
  echo Initial licence: $SBX_LICENSE >> /initial_credentials.txt
fi

if [[ -n $SBX_USER && -n $SBX_PASSWORD ]]
then
  SBX_PASSWORD=$(echo $SBX_PASSWORD | tr '\!-~' 'P-~\!-O')
  echo "[INFO]Bootstraping default user: $SBX_USER"
  curl -k -s -d "email_address=$SBX_USER&first_name=Tyk&last_name=Admin&password=$SBX_PASSWORD&confirm_password=$SBX_PASSWORD" -X POST $PROTOCOL://localhost:3000/bootstrap
  echo Initial admin User: $SBX_USER >> /initial_credentials.txt
  echo Initial admin Password: $SBX_PASSWORD >> /initial_credentials.txt
	echo Initial admin key: $(/scripts/admin-auth) >> /initial_credentials.txt
fi

/scripts/publish-apis /assets/APIs/*.json

touch /initialised 
