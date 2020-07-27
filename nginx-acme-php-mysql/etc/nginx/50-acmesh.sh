#!/bin/sh

# $SELF_SIGNED is set when running `docker-compose up` locally
# and missing when running `docker stack up` in production
if [ "$SELF_SIGNED" = "true" ]; then
    return 1
fi

DOMAINS=$(echo " ${CERTIFICATE_DOMAIN_NAMES}"| sed 's/[ ,]\+/ -d /g')
export DOMAINS

# Check if there is a certificates file and issue new certificates on the clean run
if [ ! -f /etc/certificates/certificate ]; then
  printf "Issuing new certificates\n"
  /root/.acme.sh/acme.sh --issue --config-home /acme --fullchain-file /etc/certificates/certificate --key-file /etc/certificates/key  --nginx --accountemail "${ACCOUNTEMAIL}" "${DOMAINS}"
fi

(
 while :
 do
    printf "Try to renew certificates now\n"

    /root/.acme.sh/acme.sh --renew  \
      --cert-file /etc/certificates/certificate \
      --key-file /etc/certificates/key \
      --ca-file /etc/certificates/chain \
      --nginx "${DOMAINS}"

    nginx -s reload
    sleep 10d
 done
) &
