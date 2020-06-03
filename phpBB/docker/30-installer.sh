#!/bin/sh

apk --no-cache add -f openssl curl

wget -O -  https://get.acme.sh | sh

if [ ! -f /etc/certificates/dhparams.pem ]; then
    openssl dhparam -out /etc/certificates/dhparams.pem 2048
    chmod 600 dhparams.pem
    echo "dhparams generated"
fi
