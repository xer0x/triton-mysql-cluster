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
MASTER_LOG_FILE='mysql-bin.000001'
master_log_pos=0
#master_log_pos=107

POST_INIT_SCRIPT_DIR=/docker-entrypoint-initdb.d

export MYSQL_ROOT_PASSWORD
export MYSQL_ALLOW_EMPTY_PASSWORD

# Mysql Configuration Files
#
#master: https://dev.mysql.com/doc/refman/5.0/en/replication-howto-masterbaseconfig.html
#slave:  https://dev.mysql.com/doc/refman/5.0/en/replication-howto-slavebaseconfig.html
function write_my_cnf () {
	cat >> ~/.my.cnf <<-EOF
		[client]
		#password=$MYSQL_ROOT_PASSWORD
		#host=mysql

		[mysqld]
		server-id=$CONTAINER_ID_NUMBER
		log-bin=/var/log/mysql/mysql-bin.log-
		log_bin=/var/log/mysql/mysql-bin.log_
		## enable \`show slave hosts\`:
		report_host=$master_host
		## flags for consistent innodb:
		#innodb_flush_log_at_trx_commit=1
		#sync_binlog=1
	EOF
}

function write_create_repl_user_sql () {
    FILE=$POST_INIT_SCRIPT_DIR/create_repl_user.sql
	cat >> $FILE <<-EOF
		CREATE USER '$repl_user'@'%' IDENTIFIED BY '$repl_pass';
		GRANT REPLICATION SLAVE ON *.* TO '$repl_user'@'%';
	EOF
}

function write_change_master_sql () {
	# https://dev.mysql.com/doc/refman/5.0/en/change-master-to.html
	# Warning: We are not using SSL.
	SQL_FILE=$POST_INIT_SCRIPT_DIR/change_master_to.sql
	cat >> $SQL_FILE <<-EOF
		CHANGE MASTER TO
		MASTER_HOST           = '$master_host',
		MASTER_USER           = '$repl_user',
		MASTER_PASSWORD       = '$repl_pass',
		MASTER_PORT           = $master_port,
		MASTER_CONNECT_RETRY  = 60,
		MASTER_LOG_FILE       = '$master_log_file',
		MASTER_LOG_POS        = $master_log_pos,
		RELAY_LOG             = 'mysqld-relay-bin',
		MASTER_SSL            = 0;
	EOF
}

function setup_master () {
	source /entrypoint.sh "$@"
}

function setup_slave () {
	# TODO: get existing data from master
	source /entrypoint.sh "$@"
}

# if command starts with an option, prepend mysqld
if [ "${1:0:1}" = '-' ]; then
	set -- mysqld "$@"
fi

# Get DATADIR from mysqld
DATADIR="$("$@" --verbose --help 2>/dev/null | awk '$1 == "datadir" { print $2; exit }')"

mkdir -p $POST_INIT_SCRIPT_DIR

case $TRITON_MYSQL_ROLE in
	"master" )
		echo "Running: Master"
		write_my_cnf
		write_create_repl_user_sql
		setup_master "$@"
		;;
	"slave" )
		echo "Running: Slave"
		echo
		echo "Fetching data from remote server"
		echo "Nope, don't know how to do that yet..."

		write_my_cnf
		write_create_repl_user_sql
		write_change_master_sql

		# Do the magic

		# if not downloading existing stuff:
		#source /entrypoint.sh "$@"
		setup_slave "$@"

		# if existing /var/lib/mysql:
		# download_from_master
		;;
	* )
		echo "Auto detection"
		;;
esac

# vim: filetype=sh : noexpandtab : copyindent : preserveindent : softtabstop=0 : shiftwidth=4 : tabstop=4
