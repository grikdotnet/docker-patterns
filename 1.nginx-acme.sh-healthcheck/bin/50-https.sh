#!/bin/sh

# disable globbing to use word splitting
set -f

# Check for obligatory variables
: "${CERTIFICATE_DOMAINS?}" "${LOCAL_DOMAIN?}"

WEBROOT=${WEBROOT:-"/usr/share/nginx/html"}
export ACME_DIR=${ACME_DIR:-"/acme"}
export FULLCHAIN_FILE="${ACME_DIR}/certificate"
export KEY_FILE="${ACME_DIR}/key"

if ! which openssl > /dev/null ; then
  apk add --no-cache -u openssl
fi

# Generate a self-signed certificate if there is no certificate yet, or Nginx will not start
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

if [ "${SKIP_ACME}" == "1" ]; then
    echo "Skipping ACME"
    exit 0
fi

echo "Production mode"

source acme-runner.sh
