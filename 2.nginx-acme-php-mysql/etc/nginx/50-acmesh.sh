#!/bin/sh

# disable globbing to use word splitting
set -f

# Check for obligatory variables
: "${CERTIFICATE_DOMAIN_NAMES?}" "${LOCAL_DOMAIN_NAME?}"

WEBROOT=${WEBROOT:-"/usr/share/nginx/html"}
ACME_DIR=${ACME_DIR:-"/acme"}
FULLCHAIN_FILE="${ACME_DIR}/certificate"
KEY_FILE="${ACME_DIR}/key"

echo "Installing openssl and acme.sh"

apk --no-cache add -f openssl && wget -O -  https://get.acme.sh | sh

if ! $?; then
  echo "Error installing packages"
  exit 250
fi

#Generate a self-signed certificate for develoment environment and to let Nginx start
if [ ! -f "${FULLCHAIN_FILE}" ]; then
  printf "Issuing a self-signed certificate\n"
  openssl req -x509 -newkey rsa:2048 -sha256 -days 3650 -nodes \
    -keyout "${ACME_DIR}/key.local" -out "${ACME_DIR}/certificate.local" \
    -subj /CN="${LOCAL_DOMAIN_NAME}" \
    -addext subjectAltName=DNS:"${LOCAL_DOMAIN_NAME}"
  ln -s "${ACME_DIR}/key.local" "${KEY_FILE}"
  ln -s "${ACME_DIR}/certificate.local" "${FULLCHAIN_FILE}"
else
  printf "Found a certificate\n"
fi

if [ "${SELF_SIGNED_ONLY}" = "1" ]; then
    exit 0
fi

#In a production environment

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

wait_for_nginx(){
  for _ in $(seq 5); do
    sleep 1
    response=$(wget -S -q -O /dev/null 'http://127.0.0.1:8088/health-check' 2>&1)

    if echo "${response}" | grep -qF "HTTP/1.1 200 OK" ; then
        return 0
    fi
  done
  return 1
}

acme(){
  mkdir -p "{$WEBROOT}/.well-known"
  chown nginx "${WEBROOT}/.well-known"
  /root/.acme.sh/acme.sh --test "$@" -w "$WEBROOT" \
    --config-home "$ACME_DIR" \
    --fullchain-file "$FULLCHAIN_FILE" \
    --key-file "$KEY_FILE" \
    --reloadcmd 'nginx -s reload'
  result=$?
  if $result; then
    rm -rf "${WEBROOT}/.well-known"
  fi
  return $result;
}

#A background task issuing and renewing certificates using Nginx as an http server
(
  if ! wait_for_nginx; then
    echo "Nginx is not responding"
    exit 254;
  fi

  # Issue real a certificate instead of self-signed
  if [ "$(readlink "$FULLCHAIN_FILE")" = "${ACME_DIR}/certificate.local" ]; then
    printf "Issuing new certificates ...\n"
    rm "$FULLCHAIN_FILE" "$KEY_FILE"
    # word splitting is used cause I don't know how to avoid it
    # in POSIX sh without array syntax like ${EMAIL[@]}
    if ! acme --issue $EMAIL $DOMAINS; then
      printf "Error\n";
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
) &
