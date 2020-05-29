#!/bin/sh

apk --no-cache add -f openssl curl

openssl dhparam -out /etc/cert/dhparams.pem
chmod 600 /etc/nginx/ssl/dhparams.pem

wget -O -  https://get.acme.sh | sh
alias acme.sh='/root/.acme.sh/acme.sh'


/root/.acme.sh/acme.sh --issue  \
--cert-file /etc/cert/certificate \
  --key-file /etc/cert/key \
  --ca-file /etc/cert/chain \
  -d  \
  --nginx
