#!/bin/sh
response=$(wget -S -q -O /dev/null http://127.0.0.1:8088/health-check 2>&1)

if grep -q "HTTP/1.1 200 OK" "$response" ; then
    echo "OK"
    exit 0
else
    echo "$response"
    exit 1
fi
