#!/bin/bash

ip1=$(cat ip1.txt)
ip2=$(cat ip2.txt)
ip3=$(cat ip3.txt)
ip4=$(cat ip4.txt)


cat > orchestratorScript.sh << EOL
#!/bin/bash

sudo apt-get update;
sudo apt-get -y install python3-pip;
sudo pip3 install flask;
cat > ip.json << EOF
{
	"container1":{
		"ip": "${ip1}",
		"port": "5000",
		"status": "free"
	},
	"container2":{
		"ip": "${ip1}",
		"port": "5001",
		"status": "free"
	},
	"container3":{
		"ip": "${ip2}",
		"port": "5000",
		"status": "free"
	},
	"container4":{
		"ip": "${ip2}",
		"port": "5001",
		"status": "free"
	},
	"container5":{
		"ip": "${ip3}",
		"port": "5000",
		"status": "free"
	},
	"container6":{
		"ip": "${ip3}",
		"port": "5001",
		"status": "free"
	},
	"container7":{
		"ip": "${ip4}",
		"port": "5000",
		"status": "free"
	},
	"container8":{
		"ip": "${ip4}",
		"port": "5001",
		"status": "free"
	}
}
EOF
cat > server.py << EOF
from flask import Flask, jsonify, request
import json
import threading
import time
import requests

app = Flask(__name__)
lock = threading.Lock()
request_queue = []

def send_request_to_container(container_id, container_info):
	print(f"Sending request to {container_id}")
	ip = container_info['ip']
	port = container_info['port']
	url = f'http://{ip}:{port}/run_model'
	response = requests.post(url)
	print(f"Response from {url}: {response.status_code}, {response.text}")
	print(f"Receivde response from {container_id}")
	return response.text

def update_container_status(container_id, status):
	with lock:
		with open("ip.json", "r") as f:
			data = json.load(f)
		data[container_id]["status"] = status
		with open("ip.json", "w") as f:
			json.dump(data, f)

def check_availability(data):
	free_container = None
	for container_id, container_info in data.items():
		if container_info["status"] == "free":
			free_container = container_id
			break
	return free_container

def requesting(free_container, data):
	update_container_status(free_container, "busy")
	response = send_request_to_container(free_container, data)
	update_container_status(free_container, "free")
	return response

def process_request():
	with lock:
		with open("ip.json", "r") as f:
			data = json.load(f)
	free_container = check_availability(data)
	if free_container:
		return requesting(free_container, data[free_container])
	else:
		request_queue.append('busy')
		response = None
		while(response == None):
			with lock:
				with open("ip.json", "r") as f:
					data = json.load(f)
			free_container = check_availability(data)
			if free_container:
				request_queue.pop()
				response = requesting(free_container, data[free_container])
		return response
		
@app.route("/new_request", methods=["GET"])
def new_request():
	threading.Thread(target=process_request).start()
	if len(request_queue) == 0:
		return jsonify({"message": "Request received and being processed"})
	else:
		return jsonify({"message": f"Request received and will be processed soon. {len(request_queue)} process prior to yours"})

@app.route("/hello", methods=["GET"])
def hello():
	return jsonify({"message": "Hello World"})

@app.route("/queue", methods=['GET'])
def queue():
	return jsonify({"Queue lenght": str(len(request_queue))})

if __name__ == "__main__":
	app.run(host='0.0.0.0', port=5000)

EOF
sudo python3 server.py;
EOL