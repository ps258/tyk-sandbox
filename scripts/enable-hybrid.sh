#!/bin/bash

# Script finds the admin auth token for a user and echos that.
# Any admin user will do.

PATH=/scripts:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:$PATH

ORG_ID=$(awk '/Org ID:/ {print $NF}' /initial_credentials.txt)
ADMIN_KEY=$(jq -r .admin_secret /opt/tyk-dashboard/tyk_analytics.conf)

org=$(curl -s http://localhost:3000/admin/organisations/$ORG_ID -H "Admin-Auth: $ADMIN_KEY" | jq ".hybrid_enabled = true")

curl -sX PUT http://localhost:3000/admin/organisations/$ORG_ID -H "Admin-Auth: $ADMIN_KEY" -d "$org"
