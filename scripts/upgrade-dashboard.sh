#!/bin/bash

SERVICE=dashboard
PRODUCT=tyk-$SERVICE
BINARY=tyk-analytics
BASEDIR=/opt/$PRODUCT

if [[ $# -lt 1 ]]
then
  echo Must provide $SERVICE version like 5.7.2
  exit 1
fi

if [[ -f $BASEDIR/$PRODUCT-$1 ]]
then
  # version alread installed, link it and restart
  ln -sf $BASEDIR/$PRODUCT-$1 $BASEDIR/$BINARY
  restart $SERVICE
else
  yum -y install $PRODUCT-$1
  if [[ -f $BASEDIR/$BINARY ]]
  then
    mv $BASEDIR/$BINARY $BASEDIR/$PRODUCT-$1
    ln -sf $BASEDIR/$PRODUCT-$1 $BASEDIR/$BINARY
    restart $SERVICE
  fi
fi
