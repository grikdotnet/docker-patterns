#!/bin/sh

apk --no-cache add -f openssl curl

if [ ! -f /etc/certificates/dhparams.pem ]; then
    cd /etc/certificates/ssl
    openssl dhparam -out dhparams.pem 2048
    chmod 600 dhparams.pem
    echo "dhparams generated"
fi

wget -O -  https://get.acme.sh | sh


_DOMAINS=$(echo " $CERTIFICATE_DOMAIN_NAMES"| sed 's/[ ,]\+/ -d /g')

/root/.acme.sh/acme.sh --issue  \
--cert-file /etc/certificates/certificate \
  --key-file /etc/certificates/key \
  --ca-file /etc/certificates/chain \
  -d $_DOMAINS \
  --nginx
