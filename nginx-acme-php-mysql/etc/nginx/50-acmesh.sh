#!/bin/sh

# $SELF_SIGNED is set when running `docker-compose up` locally
# and missing when running `docker stack up` in production
if [ "$SELF_SIGNED" = "true" ]; then
    return 1
fi

DOMAINS=$(echo " ${CERTIFICATE_DOMAIN_NAMES}"| sed 's/[ ,]\+/ -d /g')

if [ "$ACCOUNTEMAIL" != "test@example.com" ] && expr "$ACCOUNTEMAIL" : '\w.\+@\w.\+' >/dev/null ; then
    EMAIL_CLAUSE=" --accountemail $ACCOUNTEMAIL "
fi

# Check if there is a certificates file and issue new certificates on the clean run
if [ ! -f /etc/certificates/certificate ]; then
  printf "Issuing new certificates\n"
  if  ! nginx ; then
    printf "Error running Nginx, check configs\n"
  fi
  mkdir /usr/share/nginx/html/well-known/
  /root/.acme.sh/acme.sh --issue -w /usr/share/nginx/html/well-known/ --config-home /acme --fullchain-file /etc/certificates/certificate --key-file /etc/certificates/key $EMAIL_CLAUSE $DOMAINS
  nginx -s stop
  rm -rf /usr/share/nginx/html/well-known/
fi

(
 while :
 do
    printf "Try to renew certificates now\n"

    /root/.acme.sh/acme.sh --renew -w /usr/share/nginx/html/well-known/ \
      --cert-file /etc/certificates/certificate \
      --key-file /etc/certificates/key \
      --ca-file /etc/certificates/chain \
       $DOMAINS $EMAIL_CLAUSE

    nginx -s reload
    sleep 10d
 done
) &
