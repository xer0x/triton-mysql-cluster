#!/bin/bash

set -x
set -e

# Each Mysqld must have a unique ID
CONTAINER_ID_NUMBER=1
MASTER_IP=192.168.1.2

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
		report_host=$MASTER_IP
		## flags for consistent innodb:
		#innodb_flush_log_at_trx_commit=1
		#sync_binlog=1
	EOF
}

function write_change_master_sql () {
	# https://dev.mysql.com/doc/refman/5.0/en/change-master-to.html
	# Warning: We are not using SSL.
	SQL_FILE=/docker-entrypoint-initdb.d/change_master_to.sql
	cat >> $SQL_FILE <<-EOF
		CHANGE MASTER TO
		MASTER_HOST='$master_host_name',
		MASTER_USER='$repl_user',
		MASTER_PASSWORD='$repl_pass',
		MASTER_PORT = $port
		MASTER_CONNECT_RETRY = $interval
		MASTER_LOG_FILE='$binlog_file_name',
		MASTER_LOG_POS=$binlog_position;
		RELAY_LOG_FILE = 'relay_log_name'
		RELAY_LOG_POS = relay_log_pos
		MASTER_SSL = {0|1}
		MASTER_SSL_CA = 'ca_file_name'
		MASTER_SSL_CAPATH = 'ca_directory_name'
		MASTER_SSL_CERT = 'cert_file_name'
		MASTER_SSL_KEY = 'key_file_name'
		MASTER_SSL_CIPHER = 'cipher_list'
		CHANGE MASTER TO changes the parameters tha
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
		;;
	"slave" )
		echo "Running: Slave"
		echo
		echo "Fetching data from remote server"

		# Do the magic

		CONTAINER_ID_NUMBER=2
		write_my_cnf
		write_change_master_sql

		# Empty directory will stop the initialization of a new one
		mkdir -p $DATADIR/mysql

		;;
	* )
		echo "Auto detection"
		;;
esac

exec /entrypoint.sh "$@"

# vim: filetype=sh : noexpandtab : copyindent : preserveindent : softtabstop=0 : shiftwidth=4 : tabstop=4
