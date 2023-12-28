#!/bin/bash

sudo apt-get update;
sudo apt-get -y install libncurses5 sysbench;
sudo apt install -y libclass-methodmaker-perl;
sudo wget https://dev.mysql.com/get/Downloads/MySQL-Cluster-8.0/mysql-cluster-community-management-server_8.0.31-1ubuntu20.04_amd64.deb;
sudo dpkg -i mysql-cluster-community-management-server_8.0.31-1ubuntu20.04_amd64.deb;
mkdir /var/lib/mysql-cluster
cat > /var/lib/mysql-cluster/config.ini << EOF
[ndbd default]
NoOfReplicas=3

[ndb_mgmd]
hostname=172.31.2.2
datadir=/var/lib/mysql-cluster

[ndbd]
hostname=172.31.2.3
NodeId=2
datadir=/usr/local/mysql/data

[ndbd]
hostname=172.31.2.4
NodeId=3
datadir=/usr/local/mysql/data

[ndbd]
hostname=172.31.2.5
nodeid=5
datadir=/usr/local/mysql/data

[mysqld]
hostname=172.31.2.2
EOF
ndb_mgmd -f /var/lib/mysql-cluster/config.ini;
pkill -f ndb_mgmd;
cat > /etc/systemd/system/ndb_mgmd.service << EOF
[Unit]
Description=MySQL NDB Cluster Management Server
After=network.target auditd.service

[Service]
Type=forking
ExecStart=/usr/sbin/ndb_mgmd -f /var/lib/mysql-cluster/config.ini
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload;
systemctl start ndb_mgmd;
systemctl enable ndb_mgmd;
systemctl status ndb_mgmd;
sudo wget https://dev.mysql.com/get/Downloads/MySQL-Cluster-8.0/mysql-cluster_8.0.31-1ubuntu20.04_amd64.deb-bundle.tar;
mkdir install;
tar -xvf mysql-cluster_8.0.31-1ubuntu20.04_amd64.deb-bundle.tar -C install/;
cd install;
sudo apt-get install -y libaio1 libmecab2;
echo 'mysql-cluster-community-server mysql-cluster-community-server/root-pass password root' | sudo debconf-set-selections;
echo 'mysql-cluster-community-server mysql-cluster-community-server/re-root-pass password root' | sudo debconf-set-selections;
#sudo dpkg -i *.deb;
#sudo apt-get install -y -f;
cat > /etc/mysql/my.cnf << EOF
[mysqld]
ndbcluster

[mysql_cluster]
ndb-connectstring=172.31.2.2
EOF