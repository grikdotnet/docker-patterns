#!/bin/sh


if [ ! -f /etc/certificates/certificate ]; then
  printf "Issuing a self-signed certificate\n"
  openssl req -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes \
    -keyout /etc/certificates/key -out /etc/certificates/certificate \
    -subj /CN="${LOCAL_DOMAIN_NAME}" \
    -addext subjectAltName=DNS:"${LOCAL_DOMAIN_NAME}"
fi

export SKIP_CERTIFICATE_RENEWAL=true
