#!/bin/sh

set -e

if [ "$MYSQL_ROOT_PASSWORD" == "" ]; then
  echo WARNING: missing password env variable MYSQL_ROOT_PASSWORD
fi

innobackupex --host mysql --password=$MYSQL_ROOT_PASSWORD /data/backup
