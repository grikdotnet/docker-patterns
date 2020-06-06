#!/bin/sh

DOMAINS=$(echo " ${CERTIFICATE_DOMAIN_NAMES}"| sed 's/[ ,]\+/ -d /g')

if [ ! -f /etc/certificates/certificate ]; then
  /root/.acme.sh/acme.sh --issue  \
    --cert-file /etc/certificates/certificate \
    --key-file /etc/certificates/key \
    --ca-file /etc/certificates/chain \
    --nginx "${DOMAINS}"
fi

(
 while :
 do
    sleep 10d

    /root/.acme.sh/acme.sh --renew  \
      --cert-file /etc/certificates/certificate \
      --key-file /etc/certificates/key \
      --ca-file /etc/certificates/chain \
      --nginx "${DOMAINS}"

    nginx -s reload
 done
) &
