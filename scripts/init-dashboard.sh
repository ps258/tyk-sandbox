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

  # this method is reliable for 2.8.x -> 3.2.x
  ADMIN_SECRET=$(jq -r .admin_secret /opt/tyk-dashboard/tyk_analytics.conf)
  ORG_DATA=$(curl --silent \
    --header "admin-auth: $ADMIN_SECRET" \
    --header "Content-Type:application/json" \
    --data '{"owner_name": "Default Org.","owner_slug": "default", "cname_enabled": true, "cname": ""}' \
    http://localhost:3000/admin/organisations)

  ORG_ID=$(echo $ORG_DATA | jq -r .Meta)
  USER_JSON=$(curl --silent \
    --header "admin-auth: $ADMIN_SECRET" \
    --header "Content-Type:application/json" \
    --data '{
      "first_name": "Tyk", 
      "last_name": "Admin", 
      "email_address": "'$SBX_USER'", 
      "password":"'$SBX_CLEAR_PASSWORD'", 
      "active": true, 
      "org_id": "'$ORG_ID'", 
      "user_permissions": { "ResetPassword" : "admin", "IsAdmin": "admin" }}' \
      http://localhost:3000/admin/users)

  ACCESS_TOKEN=$(echo $USER_JSON | jq -r .Meta.access_key)

  USERID=$(curl --silent --header "authorization: $ACCESS_TOKEN" http://localhost:3000/api/users | jq -r .users[0].id)

  curl --silent \
    --header "authorization: $ACCESS_TOKEN" \
    --header "Content-Type:application/json" \
    --data '{"new_password":"'$SBX_CLEAR_PASSWORD'"}' \
    http://localhost:3000/api/users/$USERID/actions/reset


  # this method is reliable for versions 2.9.x - 3.2.x (won't work on 2.8.x)
  # curl -k -s -d "email_address=$SBX_USER&first_name=Tyk&last_name=Admin&password=$SBX_CLEAR_PASSWORD&confirm_password=$SBX_CLEAR_PASSWORD" $PROTOCOL://localhost:3000/bootstrap
  echo Initial admin User: $SBX_USER >> /initial_credentials.txt
  echo "Initial admin Password (base64 encoded):" $SBX_PASSWORD >> /initial_credentials.txt
	echo Initial admin key: $(admin-auth) >> /initial_credentials.txt
  # publish all apis from /assets/APIs
  /scripts/publish-apis /assets/APIs/*.json
fi
touch /initialised 
