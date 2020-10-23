#!/bin/bash

PORT=${ADMIN_PORT:-4040}
NAME='mailserver'

if [ ! -n "`pidof $NAME`" ]; then
    exit 1
fi
curl -sf http://localhost:${PORT} > /dev/null || exit 2
exit 0