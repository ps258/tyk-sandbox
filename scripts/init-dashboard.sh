#!/bin/bash

PROTOCOL=http

if [[ -n $TYK_LICENSE ]]
then
  echo "[INFO]Adding dashboard license $TYK_LICENSE"
  curl -k -s -d "license=$TYK_LICENSE" -X POST $PROTOCOL://localhost:3000/license
fi

if [[ -n $TYK_USER && -n $TYK_PASSWORD ]]
then
  echo "[INFO]Bootstraping default user: $TYK_USER, $TYK_PASSWORD"
  curl -k -s -d "owner_name=TYK&owner_slug=TYK&email_address=$TYK_USER&first_name=Tyk&last_name=Admin&password=$TYK_PASSWORD&confirm_password=$TYK_PASSWORD" -X POST $PROTOCOL://localhost:3000/bootstrap
  echo "Initial admin User: $TYK_USER" > /initial_credentials.txt
  echo "Initial admin Password: $TYK_PASSWORD" >> /initial_credentials.txt
fi

touch /initialised 
