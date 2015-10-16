#!/usr/bin/env bash

#function mysql () {
#    command mysql -u root -p$MYSQL_ROOT_PASSWORD $@
#}

function set_datadir () {
	#MYSQL_DATA_DIR="$("$@" --verbose --help 2>/dev/null | awk '$1 == "datadir" { print $2; exit }')"
	MYSQL_DATA_DIR="$(mysqld --verbose --help 2>/dev/null | awk '$1 == "datadir" { print $2; exit }')"
}

function add_client_to_mycnf {
	cat >> ~/.my.cnf <<-EOF
		[client]
		password=$MYSQL_ROOT_PASSWORD
		#host=mysql
	EOF
}

# Export data
# https://dev.mysql.com/doc/refman/5.6/en/replication-howto-masterstatus.html

# lock_tables for 1 hour
function lock_tables {
	local SQL="FLUSH TABLES WITH READ LOCK;"
	cat <(echo "$SQL") <(sleep 3600) | mysql &
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
	local ARCHIVE=$1
	if [ "$ARCHIVE" == "" ]; then
		echo error: archive missing filename
		return 1
	fi
	# Notes: if we exclude performance_schema mysql will complain when it starts
	#EXCLUDE="master.info auto.cnf relay-log.info machine.err machine.local.err mysql test performance_schema"
	#EXCLUDE="master.info auto.cnf relay-log.info machine.err machine.local.err test performance_schema"
	EXCLUDE="master.info auto.cnf relay-log.info machine.err machine.local.err test"
	CWD=$(pwd)
	add_client_to_mycnf
	set_datadir
	cd "$MYSQL_DATA_DIR"
	echo "SHOW MASTER STATUS;" | mysql > master.status
	echo "SHOW SLAVE STATUS;" | mysql > slave.status
	tar czf "$ARCHIVE" -X <(echo "$EXCLUDE" | tr " " "\n") .
	cd "$CWD"
	echo Wrote "$ARCHIVE"
}


# If binlog is disabled, then log name = '' and use position of '4'

#echo -n sleeping
#while [ 1 ]; do
  #echo -n .
  #sleep 60
#done

#innobackupex --host mysql --password=$MYSQL_ROOT_PASSWORD /data/backup

function archive_master () {
	# https://dev.mysql.com/doc/refman/5.6/en/replication-howto-rawdata.html

	lock_tables
	get_master_status > "$MYSQL_DATA_DIR/master.status"
	# TODO:XXX: stop mysql while copying or use xtraBackup/exbackup for innodb
	archive /tmp/backup.tar.gz
	unlock_tables
	# TODO:XXX: start_mysql_if_innodb
}

function archive_slave () {

	# TODO: any special treatment when copying a slave to a slave?

	echo TODO: archive_slave
}

#ARCHIVE=/tmp/backup.tar.gz
function import_archive () {
#https://dev.mysql.com/doc/refman/5.6/en/replication-howto-existingdata.html

	echo import_to_mysql

	if [ "$1" == "" ]; then
		echo error: missing archive filename
		return 1
	fi

	local ARCHIVE=$1

	get_archive "$ARCHIVE"

	set_datadir

	tar xvzf "$ARCHIVE" --directory "$MYSQL_DATA_DIR"

	# unlock tables -- sometimes needed if the lock is set in the archive
	#echo "UNLOCK TABLES;" | mysql
	# TODO: write to scripts to be executed after startup?

	# update slave status from master.status
	# - modify triton_mysql:triton-entrypoint.sh write_change_master_sql to read position from master.status file

	# replication configurure
}

function get_archive () {
	local ARCHIVE=$1
	if [ "$ARCHIVE" == "" ]; then
		echo error: missing archive filename
		return 1
	fi

	# TODO: retrieve from actual source
	curl https://us-east.manta.joyent.com/drew.miller/public/mysql.backup.tar.gz -o "$ARCHIVE"
}

function import () {
	import_archive /tmp/backup.tar.gz
}


# vim: filetype=sh : noexpandtab : copyindent : preserveindent : softtabstop=0 : shiftwidth=4 : tabstop=4
