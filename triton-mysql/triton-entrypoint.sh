#!/bin/bash

set -x
set -e

# TODO: Add support for stop/start of server for innoDB
# TODO: Add support for exbackup for innoDB to avoid start/stop
# TODO: Add support for GTID replication
# TODO: HA and Slave promotion

# Each Mysqld must have a unique ID
CONTAINER_ID_NUMBER=$RANDOM
master_host="master"
master_port=3306
repl_user=slaveuser
repl_pass=slavepass

# Mysql Configuration File
#
#master: https://dev.mysql.com/doc/refman/5.0/en/replication-howto-masterbaseconfig.html
#slave:  https://dev.mysql.com/doc/refman/5.0/en/replication-howto-slavebaseconfig.html
function write_my_cnf () {
	cat >> ~/.my.cnf <<-EOF
		[client]
		password=$MYSQL_ROOT_PASSWORD
		#host=mysql

		[mysqld]
		server-id=$CONTAINER_ID_NUMBER
		log-bin=mysql-bin
		## enable `show slave hosts`:
		report_host=$master_host
		## flags for consistent innodb:
		#innodb_flush_log_at_trx_commit=1
		#sync_binlog=1
	EOF
}

function write_create_repl_user_sql () {
    FILE=/docker-entrypoint-initdb.db/create_repl_user.sql
	cat >> $FILE <<-EOF
		CREATE USER '$repl_user'@'%' IDENTIFIED BY '$repl_pass';
		GRANT REPLICATION SLAVE ON *.* TO '$repl_user'@'%';
	EOF
}

function write_change_master_sql () {
	# https://dev.mysql.com/doc/refman/5.0/en/change-master-to.html
	# Warning: We are not using SSL.
	SQL_FILE=/docker-entrypoint-initdb.d/change_master_to.sql
	cat >> $SQL_FILE <<-EOF
		CHANGE MASTER TO
		MASTER_HOST           = '$master_host',
		MASTER_USER           = '$repl_user',
		MASTER_PASSWORD       = '$repl_pass',
		MASTER_PORT           = $master_port,
		MASTER_CONNECT_RETRY  = 60,
		MASTER_LOG_FILE       = '$master_log_file',
		MASTER_LOG_POS        = $master_log_pos,
		MASTER_SSL            = 0;
	EOF
}

# if command starts with an option, prepend mysqld
if [ "${1:0:1}" = '-' ]; then
	set -- mysqld "$@"
fi

# Get DATADIR from mysqld
DATADIR="$("$@" --verbose --help 2>/dev/null | awk '$1 == "datadir" { print $2; exit }')"

case $TRITON_MYSQL_ROLE in
	"master" )
		echo "Running: Master"
		write_my_cnf
		write_create_repl_user_sql
		;;
	"slave" )
		echo "Running: Slave"
		echo
		echo "Fetching data from remote server"

		# Do the magic

		CONTAINER_ID_NUMBER=2
		write_my_cnf
		write_create_repl_user_sql
		write_change_master_sql

		# Empty directory will stop the initialization of a new database
		mkdir -p $DATADIR/mysql

		;;
	* )
		echo "Auto detection"
		;;
esac

exec /entrypoint.sh "$@"

# vim: filetype=sh : noexpandtab : copyindent : preserveindent : softtabstop=0 : shiftwidth=4 : tabstop=4
