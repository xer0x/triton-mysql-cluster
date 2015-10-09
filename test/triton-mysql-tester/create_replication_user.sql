CREATE USER 'slaveuser'@'%.mydomain.com' IDENTIFIED BY 'slavepass';
GRANT REPLICATION SLAVE ON *.* TO 'slaveuser'@'%.mydomain.com';
