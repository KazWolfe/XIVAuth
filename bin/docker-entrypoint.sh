#!/usr/bin/env sh

# Bring in Jemalloc if it exists
JEMALLOC_PATH=$(find /usr/ -name "libjemalloc.so*" | sort -V | tail -n 1)
if [ -f "$JEMALLOC_PATH" ]; then
  export LD_PRELOAD="$JEMALLOC_PATH $LD_PRELOAD"
fi

# Delete server.pid if it exists
rm -f /app/tmp/pids/server.pid

exec "$@"