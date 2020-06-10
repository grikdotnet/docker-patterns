#!/bin/sh

set -e

apk add --no-cache --virtual ext-dev-dependencies $PHPIZE_DEPS binutils

apk add --no-cache fcgi

docker-php-ext-install -j$(cat /proc/cpuinfo | grep processor | wc -l) pdo_mysql

docker-php-ext-enable opcache

apk del ext-dev-dependencies

# first arg is `-f` or `--some-option`
if [ "${1#-}" != "$1" ]; then
	set -- php-fpm "$@"
fi

exec "$@"
