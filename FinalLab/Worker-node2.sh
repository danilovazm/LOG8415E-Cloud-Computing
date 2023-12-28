#!/bin/bash

sudo apt-get update;
sudo apt install -y libclass-methodmaker-perl;
wget https://dev.mysql.com/get/Downloads/MySQL-Cluster-8.0/mysql-cluster-community-data-node_8.0.31-1ubuntu20.04_amd64.deb;
sudo dpkg -i mysql-cluster-community-data-node_8.0.31-1ubuntu20.04_amd64.deb;
cat > /etc/my.cnf << EOF
[mysql_cluster]
ndb-connectstring=172.31.2.2
EOF
mkdir -p /usr/local/mysql/data;
cat > /etc/systemd/system/ndbd.service << EOF
[Unit]
Description=MySQL NDB Data Node Daemon
After=network.target auditd.service

[Service]
Type=forking
ExecStart=/usr/sbin/ndbd
ExecReload=/bin/kill -HUP $MAINPID
KillMode=process
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
sudo chmod -R 777 /usr/local/mysql/data/;
systemctl daemon-reload;
systemctl start ndbd;
systemctl enable ndbd;