Mysql cluster blueprint example for Triton
==========================================

Let's build a cluster of MySQL databases. To do it we are going to use the Docker support built into Triton. We can build a simple scalable system using Docker compose, and Joyent's container native hosting service.

### Setup this up

1. Setup a Joyent account
2. Install Docker Toolbox
3. Run this setup script for Joyent
4. Git clone this repo `git clone https://github.com/xer0x/triton-mysql-cluster`
5. Run the demo using `bash start.sh`

### Query and test your new MySQL database

#### Verify replication

    docker exec -it my_master_1 mysql
    create database demo_app;
    create table messages (message text);
    insert into messages values ('Surprise!');
    exit;
    ^D

    docker exec -it my_slave_1 mysql demo_app
    select * from demo_app;
    exit;
    ^D

#### Clone to a new slave

    docker exec -it my_master_1 mysql
    script load_dictionary.sql
    commit;
    exit;
    ^D

    ...something to make the slave happen

    docker exec -it my_master_1 /archive.sh

### Fork this and play

