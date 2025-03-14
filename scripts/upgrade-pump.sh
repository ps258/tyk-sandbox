#!/bin/bash

SERVICE=pump
PRODUCT=tyk-$SERVICE
BINARY=tyk-$SERVICE
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
	# check if this is the only install
	if [[ -f $BASEDIR/$BINARY ]]
	then
		if [[ ! -L $BASEDIR/$BINARY ]]
		then
			current_version=$(rpm -qf $BASEDIR/$BINARY --queryformat '%{VERSION}')
			mv $BASEDIR/$BINARY $BASEDIR/$PRODUCT-$current_version
		fi
	fi
	# install the new version
  yum -y install $PRODUCT-$1
  if [[ -f $BASEDIR/$BINARY ]]
  then
    mv $BASEDIR/$BINARY $BASEDIR/$PRODUCT-$1
    ln -sf $BASEDIR/$PRODUCT-$1 $BASEDIR/$BINARY
    restart $SERVICE
  fi
fi
