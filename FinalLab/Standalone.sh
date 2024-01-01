#!/bin/bash

sudo apt-get update;
sudo apt-get install -y mysql-server;
sudo apt-get install -y sysbench;
cd /opt;
wget https://downloads.mysql.com/docs/sakila-db.tar.gz;
tar -xvf sakila-db.tar.gz;
# importing sakila db to mysql distribution
mysql -u root -proot -e "SOURCE /opt/sakila-db/sakila-schema.sql";
mysql -u root -proot -e "SOURCE /opt/sakila-db/sakila-data.sql";
# performing benchmark
sysbench oltp_read_write --table-size=100000 --mysql-db=sakila --mysql-user=root --mysql-password=root prepare;
sysbench oltp_read_write --table-size=100000 --threads=6 --time=60 --max-requests=0 --mysql-db=sakila --mysql-user=root --mysql-password=root run > /home/ubuntu/results.txt;
sysbench oltp_read_write --mysql-db=sakila --mysql-user=root --mysql-password=root cleanup;