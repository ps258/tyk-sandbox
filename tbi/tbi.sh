#!/bin/bash

# entrypoint for the Tyk Base Image that sandboxes run in
# not used when running as a sandbox but is useful for debugging the base image

PATH=/scripts:/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin:$PATH

sleep infinity
