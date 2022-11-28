#!/bin/bash

# script to cap mongo org specific collections

PATH=/scripts:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:$PATH
JSFile=$(mktemp /tmp/JS.XXXXX)
# load the orgid
. /initial_credentials.txt
# populate the js file with the orgid
cat /scripts/cap-mongo-z_collections.js | sed -e "s/SBX_ORG_ID/$SBX_ORG_ID/g" > $JSFile
mongo < $JSFile
