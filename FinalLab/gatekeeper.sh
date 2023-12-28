#!/bin/bash

sudo apt-get update;
sudo apt-get -y install python3-pip;
sudo pip3 install flask;
cat > server.py << EOF
from flask import Flask, jsonify, request
import sqlite3
import json
import time
import requests

app = Flask(__name__)
ip_accepted = []  # List of ips allowed access to the service
proxyIp = None    # Ip address of the trusted host can be setted only once
initiated = False # Flag to check if the proxy api was already setted

# checks if the sql command is valid
def check_request_query(request_content):
    val_db = sqlite3.connect(":memory:")
    try:
        val_db.execute(request_content)
        valid = True
    except:
        valid = False

    val_db.close()
    return valid

# validating the client ip
def check_origin(ip):
	if ip in ip_accepted:
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