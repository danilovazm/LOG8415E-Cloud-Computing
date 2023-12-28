#!/bin/bash
ip=$(cat gate.txt)
cat > proxy.sh << EOL
#!/bin/bash

sudo apt-get update;
sudo apt-get -y install python3-pip;
sudo pip3 install flask;
sudo pip3 install sshtunnel;
sudo pip3 install pandas;
sudo pip3 install pythonping;
sudo pip3 install pymysql;
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

# Open ssh connection with manager node
def ssh_conn(pkey):
        tunnel = SSHTunnelForwarder(
                        (serversIps[0], 22),
                        ssh_username="ubuntu",
                        ssh_pkey=pkey,
                        local_bind_address=('127.0.0.1', 3306),
                        remote_bind_address=('127.0.0.1', 3306)
                    )
    tunnel.start()
    return tunnel

# estabilishing connection with the mysql database
def estabilish_conn(host):
    connection = pymysql.connect(
                    host=host,
                    user='root',
                    password='root',
                    db="sakila",
                    port=3306
                )
    return connection

# selecting the routing method Direct, Random, best server
def routingType(method):
    host = serversIps[0]
    best = 100000
    if method == 'random':
        i = random.randint(0,3)
        return workersIps[i]
    elif method == 'best':                                            # Chooses the server with the lower latency and without package loss
        for i in serversIps:
            r = ping(i, count=3)
            if best > ping.rtt_avg_ms and ping.packet_loss == 0.0:
                best = ping.rtt_avg_ms
                host = i
        return i
    else:
        return serversIps[0]

# validating the client ip
def check_origin(ip):
    if ip == gateIp:
        return True
    else:
        return False
        
# Checks if the request came from the gatekeeper then in case of True pose the query accordding to the method indicated on the request
@app.route("/new_query", methods=["POST"])
def new_query():
    if check_origin(request.remote_addr):
        tunnel = ssh_conn(request.json['pkey'])                                # creates the ssh connection with the manager
        host = routingType(request.json['method'])                             # select the server accordding to the method indicated by the user
        dbConn = estabilishConn(host)                                          # estabilish the connection with the database
        result = pd.read_sql_query(request.json['query'], connection)          # pose the query to the database
        connection.close()
        tunnel.close()                                                         # close the connections
        jsonify({"result": result})
    else:
        jsonify({"message": "Query failed"})

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)

EOF
sudo python3 server.py;
