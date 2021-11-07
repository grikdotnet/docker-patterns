#!/bin/sh

# disable globbing to use word splitting
set -f

# Check for obligatory variables
: "${CERTIFICATE_DOMAIN_NAMES?}" "${LOCAL_DOMAIN_NAME?}"

WEBROOT=${WEBROOT:-"/usr/share/nginx/html"}
ACME_DIR=${ACME_DIR:-"/acme"}
FULLCHAIN_FILE="${ACME_DIR}/certificate"
KEY_FILE="${ACME_DIR}/key"

apk --no-cache add -f openssl

#Generate a self-signed certificate for develoment environment and to let Nginx start
if [ ! -f "${FULLCHAIN_FILE}" ]; then
  printf "Issuing a self-signed certificate\n"
  openssl req -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes \
    -keyout ${ACME_DIR}/key.local -out "${ACME_DIR}/certificate".local \
    -subj /CN="${LOCAL_DOMAIN_NAME}" \
    -addext subjectAltName=DNS:"${LOCAL_DOMAIN_NAME}"
  ln -s "${ACME_DIR}/key.local" "${KEY_FILE}"
  ln -s "${ACME_DIR}/certificate.local" "${FULLCHAIN_FILE}"
else
  printf "Found a certificate\n"
fi

if [ "$SELF_SIGNED" = "1" ]; then
    echo "Local deployment mode"
    exit 0
fi

echo "Production mode"

wget -O -  https://get.acme.sh | sh

if [ ! -f "${ACME_DIR}/dhparams.pem" ]; then
    openssl dhparam -out "${ACME_DIR}/dhparams.pem" 2048
    chmod 600 dhparams.pem
    echo "Generated dhparams"
fi

# Convert a list of domains to the command parameters
DOMAINS=$(echo " ${CERTIFICATE_DOMAIN_NAMES}"| sed 's/[ ,]\+/ -d /g')

EMAIL=
if [ "${ACCOUNTEMAIL}" != "test@example.com" ] && expr "${ACCOUNTEMAIL}" : '\w.\+@\w.\+' >/dev/null ; then
    EMAIL="--accountemail $ACCOUNTEMAIL"
fi

