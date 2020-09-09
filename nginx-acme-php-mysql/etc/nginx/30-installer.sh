#!/bin/sh

echo "Installing openssl and acme.sh"

apk --no-cache add -f openssl && \
  wget -O -  https://get.acme.sh | sh
