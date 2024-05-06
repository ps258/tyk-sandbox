#!/bin/bash

# a script to pull and admin key directly out of redis

for redisKey in $(redis-cli --scan --pattern 'tyk-admin-api-*' 2> /dev/null ); do
  possibleAccessKey=$(echo $redisKey | sed 's/tyk-admin-api-//')
  if ! echo $possibleAccessKey  | grep -q -- -; then
    if [[ $(redis-cli type $redisKey) == 'string' ]]; then
      if [[ "admin" == $(redis-cli get $redisKey 2> /dev/null | jq -r .UserData.user_permissions.IsAdmin) ]]; then
        UserData_access_key=$(redis-cli get $redisKey 2> /dev/null | jq -r .UserData.access_key )
        if [[ $UserData_access_key == $possibleAccessKey ]]; then
          echo $UserData_access_key
          exit 0
        fi
      fi
    fi
  fi
done
