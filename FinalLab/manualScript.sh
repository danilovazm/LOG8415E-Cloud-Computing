#!/bin/bash

cd install;
sudo dpkg -i *.deb;
sudo apt-get install -y -f;
cat > /etc/mysql/my.cnf << EOF
[mysqld]
ndbcluster

[mysql_cluster]
ndb-connectstring=172.31.2.2
EOF
cd /opt;
sudo wget https://downloads.mysql.com/docs/sakila-db.tar.gz;
tar -xvf sakila-db.tar.gz;
mysql -u root -proot -e "SOURCE /opt/sakila-db/sakila-schema.sql";
mysql -u root -proot -e "SOURCE /opt/sakila-db/sakila-data.sql";
sysbench oltp_read_write --table-size=100000 --mysql-db=sakila --mysql-user=root --mysql-password=root prepare;
sysbench oltp_read_write --table-size=100000 --threads=6 --time=60 --max-requests=0 --mysql-db=sakila --mysql-user=root --mysql-password=root run > /home/ubuntu/results.txt;
sysbench oltp_read_write --mysql-db=sakila --mysql-user=root --mysql-password=root cleanup;
