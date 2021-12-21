#!/bin/bash

# serve plugins from $PLUGINDIR
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/scripts:/opt/tyk-sync:$PATH

PLUGINDIR=${1:-/opt/tyk-plugins}

if [[ -d "$PLUGINDIR" ]]; then
	echo "[INFO]Serving from '$PLUGINDIR'"
	# python 3.9 allows this invocation
  	#python3 -m http.server --bind 127.0.0.1 --directory "$PLUGINDIR" 8000

	# python 3.6 is doesn't have --directory
	cd "$PLUGINDIR" && python3 -m http.server --bind 127.0.0.1 8000
else
  echo "[FATAL]'$PLUGINDIR' doesn't exist or isn't a directory"
fi
