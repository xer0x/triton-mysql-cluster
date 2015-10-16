

function set_datadir () {

	# TODO: import a the `mysql --get-data-dir` command from triton-mysql/triton-entrypoint.sh

	OS=$(uname -s)
	MYSQL_DIR=/var/lib/mysql

	if [ "$OS" == "Darwin" ]; then
		# We assume Homebrew installed Mysql
		MYSQL_DIR=/usr/local/var/mysql
	fi
}

function add_client_to_mycnf {
	cat >> ~/.my.cnf <<-EOF
		[client]
		password=$MYSQL_ROOT_PASSWORD
		host=mysql
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
	EXCLUDE="master.info auto.cnf relay-log.info machine.err machine.local.err mysql test performance_schema"
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

function archive_master () {
	# https://dev.mysql.com/doc/refman/5.6/en/replication-howto-rawdata.html

	lock_tables
	get_master_status > $MYSQL_DIR/master.status
	# TODO:XXX: stop mysql while copying or use xtraBackup/exbackup for innodb
	archive /tmp/backup.tar.gz
	unlock_tables
	# TODO:XXX: start_mysql_if_innodb
}

function archive_slave () {

	# TODO: any special treatment when copying a slave to a slave?

	echo TODO: archive_slave
}

function import_to_mysql () {
#https://dev.mysql.com/doc/refman/5.6/en/replication-howto-existingdata.html

	echo import_to_mysql
	echo TODO: everything

	#curl gets these files

	# unlock tables -- sometimes needed?
	# update slave status from master.status
	# replication configurure
}


# vim: filetype=sh : noexpandtab : copyindent : preserveindent : softtabstop=0 : shiftwidth=4 : tabstop=4
