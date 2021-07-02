# This directory contains RPMs that are the same no matter what tyk version installed

## My RPM containing the root,intermediate and server certs to be used by the gateway for https
Leave this out to have the container create a self signed certificate during initialisation
    home-certificates-1.0.3-1.any-x86_64.rpm

## Mongo, redis and dependencies

These are now installed during the os build

## latest version of tyk-sync
    tyk-sync-1.2.0-1.x86_64.rpm
