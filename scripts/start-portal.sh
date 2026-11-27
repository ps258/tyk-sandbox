#!/bin/bash

PATH=/scripts:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:$PATH

PORTAL_LOG_LEVEL=$TYK_LOGLEVEL
export PORTAL_LOG_LEVEL

command=/opt/portal/dev-portal
conf=/opt/portal/portal.conf
log=/var/log/tyk-portal.log
ci $conf

# refuse to start if its already running
if pgrep -x $(basename $command) > /dev/null
then
  echo "[FATAL]$command running. Not starting another";
  exit 1
fi

# startup
cd /opt/portal
if [[ ! -f .bootstrapped ]]; then
  source /initial_credentials.txt
  # Connect the portal to this sandbox's dashboard
  # Build the provider json
  provider=()
  if [[ -n $SBX_ADMIN_API_KEY && -n $SBX_ORG_ID ]]; then
    provider=(-provider-name $HOSTNAME -provider-type tyk-pro
      -provider-data "{\"URL\":\"http://localhost:3000\",\"Secret\":\"$SBX_ADMIN_API_KEY\",\"OrgID\":\"$SBX_ORG_ID\"}")
  else
    echo "[WARN]No dashboard admin key or org id in /initial_credentials.txt, bootstrapping the portal without a provider"
  fi
  echo -user $SBX_USER -pass $(echo $SBX_PASSWORD | base64 -d) >> .bootstrapped
  $command -bootstrap -first Tyk -last Admin -user $SBX_USER -pass $(echo $SBX_PASSWORD | base64 -d) "${provider[@]}" --conf $conf &>> $log &
else
  $command --conf $conf &>> $log &
fi
err=$?
sleep 1

# check if its running
if ! pgrep -x $(basename $command) > /dev/null
then
  echo "[FATAL]$command exited with $err and didn't start" 1>&2
  echo "[FATAL]Check $log for errors" 1>&2
  exit 1
else
  echo "[INFO]$command started. Logs are in $log"
fi
