#!/bin/bash

set -e
#set -x

master_host=master
slave_host=slave

mysql_master=( mysql --host=master -uroot )
mysql_slave=( mysql --host=slave -uroot )

MYSQL_DATABASE="test";

if [ ! -z "$MYSQL_ROOT_PASSWORD" ]; then
	mysql_master+=( -p"${MYSQL_ROOT_PASSWORD}" )
	mysql_slave+=( -p"${MYSQL_ROOT_PASSWORD}" )
fi

WAIT_FOR_SECONDS=500

function wait_for () {
	NAME=$1
	HOST=$2
	echo "Waiting for mysql connection to ${NAME}."
	for i in {$WAIT_FOR_SECONDS..0}; do
		if echo 'SELECT 1' | "${HOST[@]}" &> /dev/null; then
			break
		fi
		echo -n '.'
		sleep 1
	done
	if [ "$i" = 0 ]; then
		echo '..failed.'
		exit 0
	fi
}

wait_for master mysql_master

if [ "$MYSQL_DATABASE" ]; then
	echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` ;" | "${mysql_master[@]}"
	mysql_master+=( "$MYSQL_DATABASE" )
fi

"${mysql_master[@]}" <<-EOSQL
	CREATE TABLE messages (message text);
	INSERT INTO messages VALUES ("hello world");
	COMMIT;
EOSQL

wait_for slave mysql_slave

echo "SELECT message FROM messages ;" | "${mysql_master[@]}"

#exec "$@"

# vim: noexpandtab : copyindent : preserveindent : softtabstop=0 : shiftwidth=4 : tabstop=4
