#!/bin/bash

# script to return redis masters back to their master ports

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/scripts
MASTER_PORT=6379
REPLICA_PORTS=6380
VERBOSE=0
TMPFILES=''
PROGNAME=$0

trap 'rm -f $TMPFILES' 0 1 2 3 15

while getopts hv OPTION
do
  case $OPTION in
    v) VERBOSE=1
      ;;
    *) echo "Usage: $0 <-h> <-v>"
       echo "  Will return the master replica to port $MASTER_PORT on the local machine"
       exit 0
      ;;
  esac
done

function fallbackByMaster {
  # give a master now, work out which replica to promote and promote it
  typeset _IP
  typeset _uid
  typeset _replica
  typeset _replicaIP
  typeset _replicaPort
  _IP=$1
  _uid=$(grep $_IP $ClusterNodes | awk '/master/ {print $1}' | head -1)
  _replica=$(grep $_uid $ClusterNodes | awk '!/master/ {print $2}')
  _replicaIP=$(echo $_replica | cut -d: -f1)
  _replicaPort=$(echo $_replica |  cut -d: -f2)
  echo "[INFO]$PROGNAME: rebalancing cluster by master with 'redis-cli $redisPW -h $_replicaIP -p $_replicaPort -c cluster failover', please recheck in a minute"
  redis-cli $redisPW -h $_replicaIP -p $_replicaPort -c cluster failover
}

function failbackByReplica {
  # promote the given replica to master
  typeset _IP
  _IP=$1
  echo "[INFO]$PROGNAME: rebalancing cluster by replica with 'redis-cli $redisPW -h $_IP -p $MASTER_PORT -c cluster failover', please recheck in a minute"
  redis-cli $redisPW -h $_IP -p $MASTER_PORT -c cluster failover
}

# find port to connect to. Only care about local ports
Connected=0
for MyIP in $(host.sh $(uname -n))
do
  for port in $(awk '/^port / {print $NF}' /etc/redis*.conf)
  do
    redisPW=$(awk '/^requirepass/ {print $2}' /etc/redis*.conf | head -1)
    if [[ -n $redisPW ]]
    then
      redisPW="-a $redisPW"
    fi
    if timeout 3 redis-cli $redisPW -h $HOSTNAME -p $port ping &>> /dev/null
    then
      Connected=1
      break
    fi
  done
  if [[ $Connected -eq 1 ]]
  then
    break
  fi
done
if [[ $Connected -eq 0 ]]
then
  echo "[FATAL]$PROGNAME: Unable to connect to any redis instance. Giving up!"
  exit 1
fi

# get cluster info
ClusterNodes=$(mktemp /tmp/redis.XXXXXX)
TMPFILES="$TMPFILES $ClusterNodes"
redis-cli $redisPW -h $MyIP -p $port cluster nodes > $ClusterNodes

# find the master and replicas
if [[ $VERBOSE -ne 0 ]]
then
  echo "[INFO]$0: redis0clie connected to $MyIP port=$port"
  for master in $(awk '/master/ {print $1}' $ClusterNodes | sort)
  do
    echo
    grep $master $ClusterNodes | grep master
    grep $master $ClusterNodes | grep -v master
  done
fi

masterCount=$(awk '/master/ && !/,fail/ {print $2}' $ClusterNodes | cut -d: -f1 | wc -l)
if [[ $masterCount -lt 3 ]]
then
  echo "[FATAL]$PROGNAME: Not enough redis masters! Have $masterCount, need 3 " $(awk '/master/ {print $2}' $ClusterNodes | sort -u | xargs)
fi

# do we have a slave port on $MASTER_PORT? If so, return it to a master
if grep -q " $MyIP:" $ClusterNodes
then
  # MyIP is in cluster nodes. Is it listening?
  if ! awk '$2~/'$MyIP':'$MASTER_PORT'/' $ClusterNodes | grep -q disconnected
  then
    # is $MASTER_PORT a slave?
    if awk '$2~/'$MyIP':'$MASTER_PORT'/ {print $3}' $ClusterNodes | grep -q slave
    then
      # promote to master
      echo Current State
      /scripts/check-redis
      echo 
      failbackByReplica $MyIP
    fi
  else
    echo
    echo "[WARN]$PROGNAME: $MyIP:'$MASTER_PORT' is disconnected. Will rebalance when it reconnects"
  fi
fi
