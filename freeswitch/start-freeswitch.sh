#!/bin/bash
set -euo pipefail

DB_HOST_ENV="${DB_HOST:-postgres}"
DB_PORT_ENV="${DB_PORT:-5432}"

echo "Waiting for database ${DB_HOST_ENV}:${DB_PORT_ENV} ..."
until bash -c "</dev/tcp/${DB_HOST_ENV}/${DB_PORT_ENV}" 2>/dev/null; do
  printf '.'
  sleep 1
done
echo " OK"

exec /usr/bin/freeswitch -rp -nonat -u www-data -g dialout


