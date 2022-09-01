#!/bin/sh
set -e

# Puma is evil, so this "fixes" the problem.
rm -f /app/tmp/pids/server.pid

exec "$@"
