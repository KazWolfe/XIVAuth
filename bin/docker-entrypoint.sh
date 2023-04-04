#!/usr/bin/env sh

# Delete server.pid if it exists
rm -f /app/tmp/pids/server.pid

exec "$@"