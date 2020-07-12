#!/bin/sh

set -e

apk add --no-cache --virtual ext-dev-dependencies $PHPIZE_DEPS autoconf binutils dpkg-dev file g++ gcc libc-dev make pkgconf re2c

if ! php -m | grep -q 'pdo_mysql' ; then
    docker-php-ext-install -j"$(grep -c processor /proc/cpuinfo)" pdo_mysql
fi

docker-php-ext-enable opcache

apk del ext-dev-dependencies

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- php-fpm "$@"
fi

exec "$@"
