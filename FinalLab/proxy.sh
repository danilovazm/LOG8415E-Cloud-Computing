#!/bin/bash
ip=$(cat gate.txt)
cat > proxy.sh << EOL
#!/bin/bash

sudo apt-get update;
sudo apt-get -y install python3-pip;
sudo pip3 install flask;
sudo pip3 install sshtunnel;
sudo pip3 install pandas;
cat > server.py << EOF
from flask import Flask, jsonify, request
import pymysql
import pandas as pd
import random
from sshtunnel import SSHTunnelForwarder
from pythonping import ping



app = Flask(__name__)
serversIps = ['172.31.2.2', '172.31.2.3', '172.31.2.4', '172.31.2.5']
gateIp = ${ip}

def ssh_conn():
        tunnel = SSHTunnelForwarder(
        (cluster_hosts[0], 22),
        ssh_username="ubuntu",
        ssh_pkey="labsuser.pem",
        local_bind_address=('127.0.0.1', 3306), #SQL port
        remote_bind_address=('127.0.0.1', 3306)
    )
    tunnel.start()

# estabilishing connection with the mysql database
def estabilish_conn():
    connection = pymysql.connect(
                    host=hostname,
                    user='root',
                    password='root',
                    db="sakila",
                    port=3306
                )

# selecting the routing method Direct, Random, best server
def routingType(method):
    host = serversIps[0]
    best = 100000
    if method == 'direct':
        return serversIps[0]
    elif method == 'random':
        i = random.randint(0,3)
        return workersIps[i]
    elif method == 'best':
        for i in serversIps:
            r = ping(i, count=3)
            if best > ping.rtt_avg_ms and ping.packet_loss == 0.0:
                best = ping.rtt_avg_ms
                host = i
        return i
            

    

# validating the client ip
def check_origin(ip):
    if ip == gateIp:
        return True
    else:
        return False
        
# validates the incoming request and depending on the validation accept or denies the request
@app.route("/new_query", methods=["POST"])
def new_query():
    if check_origin(request.remote_addr) and check_request_query(request.json['query']):
        response = request.post(proxyIp, data={"query": request.json['query'], "method": request.json['method']}
        jsonify({"message": response})
    else:
        jsonify({"message": "Query failed"})

# initiate the ip value of the proxy, can be used only once, is not possible to alter the proxy address once is initialized
@app.route("/initiate", methods=["POST"])
def initiate():
    if not initiated and check_origin(request.remote_addr):
        initiated = True
        proxyIp = request.json['ip']
        jsonify({"message": "Initialization completed"})
    else:
        jsonify({"message": "Operation not allowed"})

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)

EOF
sudo python3 server.py;