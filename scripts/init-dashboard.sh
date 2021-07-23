#!/bin/bash

PROTOCOL=http

if [[ -n $SBX_LICENSE ]]
then
  echo "[INFO]Adding dashboard license $SBX_LICENSE"
  curl -k -s -d "license=$SBX_LICENSE" -X POST $PROTOCOL://localhost:3000/license
fi

if [[ -n $SBX_USER && -n $SBX_PASSWORD ]]
then
  SBX_PASSWORD=$(echo $SBX_PASSWORD | tr '\!-~' 'P-~\!-O')
  echo "[INFO]Bootstraping default user: $SBX_USER, $SBX_PASSWORD"
  curl -k -s -d "owner_name=TYK&owner_slug=TYK&email_address=$SBX_USER&first_name=Tyk&last_name=Admin&password=$SBX_PASSWORD&confirm_password=$SBX_PASSWORD" -X POST $PROTOCOL://localhost:3000/bootstrap
  curl -k -s -d "owner_name=TYK&email_address=$SBX_USER&first_name=Tyk&last_name=Admin&password=$SBX_PASSWORD&confirm_password=$SBX_PASSWORD" -X POST $PROTOCOL://localhost:3000/bootstrap
  echo "Initial admin User: $SBX_USER" > /initial_credentials.txt
  echo "Initial admin Password: $SBX_PASSWORD" >> /initial_credentials.txt
fi

touch /initialised 
