#!/bin/sh


apk --no-cache add -f openssl curl
echo "Installed openssl and curl"

wget -O -  https://get.acme.sh | sh
echo "Installed acme.sh"

if [ ! -f /etc/certificates/dhparams.pem ]; then
    openssl dhparam -out /etc/certificates/dhparams.pem 2048
    chmod 600 dhparams.pem
    echo "generated dhparams"
fi
