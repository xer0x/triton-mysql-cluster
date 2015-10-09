mysql> create database hello;
Query OK, 1 row affected (0.00 sec)

mysql> use hello;
Database changed

mysql> create table messages (message text);
Query OK, 0 rows affected (0.01 sec)

mysql> insert into messages values ('hello worlds');
Query OK, 1 row affected (0.01 sec)

mysql> commit;
Query OK, 0 rows affected (0.00 sec)



