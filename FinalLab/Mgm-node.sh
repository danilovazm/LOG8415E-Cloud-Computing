#!/bin/bash

sudo apt-get update;
sudo apt-get install -y sysbench;
sudo apt-get -y install libncurses5;
mkdir -p /opt/mysqlcluster/home;
cd /opt/mysqlcluster/home;
wget http://dev.mysql.com/get/Downloads/MySQL-Cluster-7.2/mysql-cluster-gpl-7.2.1-linux2.6-x86_64.tar.gz;
tar xvf mysql-cluster-gpl-7.2.1-linux2.6-x86_64.tar.gz;
ln -s mysql-cluster-gpl-7.2.1-linux2.6-x86_64 mysqlc;
echo 'export MYSQLC_HOME=/opt/mysqlcluster/home/mysqlc' > /etc/profile.d/mysqlc.sh;
echo 'export PATH=$MYSQLC_HOME/bin:$PATH' >> /etc/profile.d/mysqlc.sh;
source /etc/profile.d/mysqlc.sh;
mkdir -p /opt/mysqlcluster/deploy;
cd /opt/mysqlcluster/deploy;
mkdir conf;
mkdir mysqld_data;
mkdir ndb_data;
cd conf;
cat > my.cnf << EOL
[mysqld]
ndbcluster
datadir=/opt/mysqlcluster/deploy/mysqld_data
basedir=/opt/mysqlcluster/home/mysqlc
port=3306
EOL
cat > config.ini << EOL
[ndb_mgmd]
hostname=172.31.2.2
datadir=/opt/mysqlcluster/deploy/ndb_data
nodeid=1

[ndbd default]
noofreplicas=3
datadir=/opt/mysqlcluster/deploy/ndb_data

[ndbd]
hostname=172.31.2.3
nodeid=3

[ndbd]
hostname=172.31.2.4
nodeid=4

[ndbd]
hostname=172.31.2.5
nodeid=5

[mysqld]
nodeid=50
EOL
cd /opt/mysqlcluster/home/mysqlc;
sudo scripts/mysql_install_db --no-defaults --datadir=/opt/mysqlcluster/deploy/mysqld_data;
cd /opt/mysqlcluster/home/mysqlc/bin/;
sudo /opt/mysqlcluster/home/mysqlc/bin/ndb_mgmd -f /opt/mysqlcluster/deploy/conf/config.ini --initial --configdir=/opt/mysqlcluster/deploy/conf;
mysqld --defaults-file=/opt/mysqlcluster/deploy/conf/my.cnf --user=root;
cd /opt;
sudo wget https://downloads.mysql.com/docs/sakila-db.tar.gz;
tar -xvf sakila-db.tar.gz;
mysql -u root -proot -e "SOURCE /opt/sakila-db/sakila-schema.sql";
mysql -u root -proot -e "SOURCE /opt/sakila-db/sakila-data.sql";
sysbench oltp_read_write --table-size=100000 --mysql-db=sakila --mysql-user=root --mysql-password=root prepare;
sysbench oltp_read_write --table-size=100000 --threads=6 --time=60 --max-requests=0 --mysql-db=sakila --mysql-user=root --mysql-password=root run > /home/ubuntu/results.txt;
sysbench oltp_read_write --mysql-db=sakila --mysql-user=root --mysql-password=root cleanup;