#!/bin/sh

set -f

error()
{
    echo "Error: $*" >&2
    exit 1
}

while test $# -gt 0
do
    case "$1" in
    --webroot)
        shift
        [ $# = 0 ] && break
        WEBROOT="$1"
        shift;;
    --acme-dir)
        shift
        [ $# = 0 ] && break
        ACME_DIR="$1"
        shift;;
    --domains)
        shift
        [ $# = 0 ] && break
        CERTIFICATE_DOMAINS="$1"
        shift;;
    --email)
        shift
        ACCOUNTEMAIL="$1"
        shift;;
    esac
done

if [ -z "${WEBROOT}" ]; then
  error Missing --webroot parameter
fi
if [ ! -d "${WEBROOT}" ]; then
  error "Invalid webroot path"
fi
if [ ! -w "${WEBROOT}" ]; then
  error "No write permissions for webroot path"
fi

if [ -z "${CERTIFICATE_DOMAINS}" ]; then
  error "Missing --domains parameter"
fi

if [ -z "${ACME_DIR}" ]; then
  echo "Assuming /acme path for an ACME script folder"
  ACME_DIR="/acme"
fi

if ! mkdir -p "${ACME_DIR}"; then
  error "Invalid permissions for ${ACME_DIR}"
fi

if ! which openssl > /dev/null ; then
  apk add --no-cache -u openssl
fi

if [ ! -f /root/.acme.sh/acme.sh ]; then
  apk add --no-cache -u acme.sh
fi

if [ ! -f "${ACME_DIR}/dhparams.pem" ]; then
    openssl dhparam -out "${ACME_DIR}/dhparams.pem" 2048
    chmod 600 "${ACME_DIR}/dhparams.pem"
    echo "Generated dhparams"
fi

FULLCHAIN_FILE=${FULLCHAIN_FILE:-"${ACME_DIR}/certificates.pem"}
KEY_FILE=${KEY_FILE:-"${ACME_DIR}/private.key"}

# Convert a list of domains to the command parameters
DOMAINS=$(echo " ${CERTIFICATE_DOMAINS}"| sed 's/[ ,]\+/ -d /g')

EMAIL=
if [ "${ACCOUNTEMAIL}" != "test@example.com" ] && expr "${ACCOUNTEMAIL}" : '\w.\+@\w.\+' >/dev/null ; then
    EMAIL="--accountemail $ACCOUNTEMAIL"
fi

# This script is started in the background before nginx
# But ACME requires a web server to validate the domain ownership, so let's wait for Nginx to start
for _ in $(seq 5); do
  sleep 1
  if pgrep "nginx: worker process" > /dev/null ; then
    nginx_running=1
    break
  fi
done

if [ -z "$nginx_running" ]; then
  echo "Nginx did not start in 5 seconds, terminating"
  exit 54
fi


# Issue an actual certificate instead of a self-signed one
if [ ! -f "${ACME_DIR}/certificates.pem" ] || [ "$(readlink "$FULLCHAIN_FILE")" == "${ACME_DIR}/certificate.local" ]; then
  printf "Issuing new certificates ...\n"
  # word splitting is used cause I don't know how to avoid it
  # in POSIX sh without array syntax like ${EMAIL[@]}

  acme.sh --test --issue $EMAIL $DOMAINS"$@" -w "${WEBROOT}" \
    --config-home "${ACME_DIR}" \
    --fullchain-file "${ACME_DIR}/acme-fullchain.pem" \
    --key-file "${ACME_DIR}/acme.key"
  result=$?

  if [ $result ] ; then
    echo "result: $result"

    ln -s "${ACME_DIR}/key" "${KEY_FILE}"
    ln -s "${ACME_DIR}/certificate.local" "${FULLCHAIN_FILE}"

    nginx -s reload
    #rm -rf "${WEBROOT}/.well-known"
  else
    printf "Error issuing certtificate(s)\n";
    exit 250;
  fi
  printf "OK\n";
fi

# certificate renewal loop
while :
do
  /root/.acme.sh/acme.sh --cron --config-home "$ACME_DIR"
  sleep 1d
done


