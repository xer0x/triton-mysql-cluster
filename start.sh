#!/usr/bin/env bash

export MYSQL_PASSWORD=any_password_will_do

make clean;

make build;

make deploy;