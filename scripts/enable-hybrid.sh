#!/bin/bash

# Script to set hybrid_enabled to true in the all the organisations found

PATH=/scripts:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:$PATH

ADMIN_KEY=$(jq -r .admin_secret /opt/tyk-dashboard/tyk_analytics.conf)

for ORG_ID in $(curl -s http://localhost:3000/admin/organisations -H "Admin-Auth: $ADMIN_KEY" | jq -r .organisations[].id)
do
	echo "[INFO]Enabling hybrid on org_id $ORG_ID"
	org=$(curl -s http://localhost:3000/admin/organisations/$ORG_ID -H "Admin-Auth: $ADMIN_KEY" | jq ".hybrid_enabled = true")
	# echo $org | jq .
	curl -sX PUT http://localhost:3000/admin/organisations/$ORG_ID -H "Admin-Auth: $ADMIN_KEY" -d "$org"
done
