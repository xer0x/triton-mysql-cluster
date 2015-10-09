#!/bin/bash

set -e

OS=$(uname -s)
MYSQL_DIR=/var/lib/mysql

if [ "$OS" == "Darwin" ]; then
	# We assume Homebrew installed Mysql
	MYSQL_DIR=/usr/local/var/mysql
fi

function setup_client {
	cat >> ~/.my.cnf <<-EOF
		[client]
		password=$MYSQL_ROOT_PASSWORD
		host=mysql
		[mysqld]
		server-id=2
	EOF
}

# Export data
# https://dev.mysql.com/doc/refman/5.6/en/replication-howto-masterstatus.html

function lock_tables {
	mysql & <<-EOSQL
		FLUSH TABLES WITH READ LOCK;
	EOSQL

	LOCK_PID=$!
}

function unlock_tables {
	kill $LOCK_PID
}

function get_master_status () {
	mysql <<-EOSQL
		SHOW MASTER STATUS;
	EOSQL
}

# If using InnoDB tables then either shutdown DB, or use Innobackupex / Percona's Exbackup
# check: SELECT distinct engine FROM INFORMATION_SCHEMA.TABLES

# a. Shutdown method
#mysqladmin shutdown;
# or
#mysql.server stop;


function archive () {
	if [ "$1" == "" ]; then
		echo error: archive missing filename
		return -1
	fi
	# TODO: do we need special handling for the 'mysql' db directory?
	EXCLUDE="master.info auto.cnf relay-log.info machine.err machine.local.err test performance_schema"
	CWD=$(pwd)
	cd $MYSQL_DIR
	tar czf $1 -X <(echo "$EXCLUDE" | tr " " "\n") .
	cd $CWD
}


# If binlog is disabled, then log name = '' and use position of '4'

#echo -n sleeping
#while [ 1 ]; do
  #echo -n .
  #sleep 60
#done

#innobackupex --host mysql --password=$MYSQL_ROOT_PASSWORD /data/backup

function extract_datafiles () {
	lock_tables
	get_master_status > $MYSQL_DIR/master.status
	#if_has_innodb
		#if_using_exbackup
			#exclude_innodb_from_tar
			#add_exbackup_to_tar
		#else_
			#stop_mysql_if_innodb
		#fi_
	#fi_
	archive /tmp/backup.tar.gz
	unlock_tables
	#start_mysql_if_innodb
}

function main () {

	echo Triton MySQL Container

	# check consul to learn how we should configure ourselves

	# if master

		# https://dev.mysql.com/doc/refman/5.6/en/replication-howto-rawdata.html

		extract_datafiles

		#nginx serves these files

	# if slave

		#https://dev.mysql.com/doc/refman/5.6/en/replication-howto-existingdata.html

		#curl gets these files

		# unlock tables -- sometimes needed?
		# update slave status from master.status
		# replication configurure
}

main

# vim: filetype=sh : noexpandtab : copyindent : preserveindent : softtabstop=0 : shiftwidth=4 : tabstop=4
