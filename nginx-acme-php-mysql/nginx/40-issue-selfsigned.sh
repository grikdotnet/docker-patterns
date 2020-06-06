#!/bin/sh

DOMAINS=$(echo " ${CERTIFICATE_DOMAIN_NAMES}"| sed 's/[ ,]\+/ -d /g')


