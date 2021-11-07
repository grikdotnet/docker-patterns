#!/bin/sh

# disable globbing to use word splitting
set -f

# This script is started in the background before nginx
# But ACME requires a web server to validate the domain ownership, so let's wait for Nginx to start
  for _ in $(seq 5); do
    sleep 1
    pid=$(cat /var/run/nginx.pid)

    if echo "${response}" | grep -qF "HTTP/1.1 200 OK" ; then
        return 0
    fi
  done
  return 1
}

acme(){
  mkdir -p "${WEBROOT}/.well-known"
  chown nginx "${WEBROOT}/.well-known"
  /root/.acme.sh/acme.sh "$@" -w "$WEBROOT" \
    --config-home "$ACME_DIR" \
    --fullchain-file "$FULLCHAIN_FILE" \
    --key-file "$KEY_FILE" \
    --reloadcmd 'nginx -s reload'
  result=$?
  if [ $result -eq 0 ]; then
    rm -rf "${WEBROOT}/.well-known"
  fi
  return $result;
}

if ! wait_for_nginx; then
  echo "Nginx is not responding"
  exit 254;
fi

# Issue a real certificate instead of self-signed
if [ "$(readlink "$FULLCHAIN_FILE")" = "${ACME_DIR}/certificate.local" ]; then
  printf "Issuing new certificates ...\n"
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

