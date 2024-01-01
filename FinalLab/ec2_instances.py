import boto3
import subprocess, pprint, time
import util
import requests

def EC2_instances(ec2_client, sgId):
    instanceIds = []
    amiId = 'ami-06aa3f7caf3a30282' #Os image that will be used in the vm
    ClusterPrivateIps = ['172.31.2.3', '172.31.2.4', '172.31.2.5', '172.31.2.2', '172.31.2.6', '172.31.2.7']
    #subnet = util.fetch_subnet(ec2_client)[0]

    # creates key pair and saves the secret key locally
    def create_key_pair(KPName):
        key = ec2_client.create_key_pair(KeyName=KPName)
        private_key = key['KeyMaterial']
        with open(f'{KPName}.pem', 'w') as key_file:
            key_file.write(private_key)
        return KPName
    
    # open and load the instance bash script into a string variable
    def launch_worker():
        with open("Worker-node2.sh", "r") as file:
            script = file.read()
        return script

    def launch_gate():
        with open("gate.sh", "r") as file:
            script = file.read()
        return script

    def launch_proxy():
        with open("proxy.sh", "r") as file:
            script = file.read()
        return script
    
    def launch_mgm():
        with open("Mgm-node2.sh", "r") as file:
            script = file.read()
        return script

    def scripts(role):
        if role == 'worker':
            return launch_worker()
        elif role == 'mgm' :
            return launch_mgm()
        elif role == 'gate':
            return launch_gate()
        elif role ==  'proxy':
            return launch_proxy()
            
    # ec2 instance launcher
    def launch_instance(KPName, Itype, privateIp = None, role = 'worker', proxySg = None):
        response = ec2_client.run_instances(
                    PrivateIpAddress=privateIp,
                    SubnetId='subnet-0facea78a1e94b6cd',                                # the subnet which the selected private ip are part of
                    ImageId=amiId,
                    MinCount=1,
                    MaxCount=1,
                    InstanceType=Itype,
                    KeyName=KPName,
                    SecurityGroupIds=[proxySg] if role == 'proxy' else [sgId],
                    UserData=scripts(role) # passing the loaded bash script to the instance
        )
        ec2 = boto3.resource('ec2')
        id = response['Instances'][0]['InstanceId']
        instance = ec2.Instance(id)
        instance.wait_until_running()
        instance.reload()
        
        pprint.pprint(instance.public_ip_address)
        return id, instance.public_ip_address               # returning the id and public ip address of the instance

    # launch the diffent set of instances
    def launch_cluster(KPName, type):
        for i in range(3):
            instanceIds.append(launch_instance(KPName, type, ClusterPrivateIps[i], 'worker'))

    # store ip adress of instances in files
    def storeIpAddresses(instanceIds):
        with open(f"gate.txt", "w") as file:
            file.write(instanceIds[1])

    # sending proxy ip to gatekeeper
    def initiate_gatekeeper(ip):
        requests.post(f'http://{ip}:5000/initiate', data={'ip': ip})
            

    # creating key pair and lauching the instances
    KPName = create_key_pair('3rd-assign-key')
    instanceIds.append(launch_instance(KPName, 'm4.large', ClusterPrivateIps[-3], 'mgm'))     # launching manager
    time.sleep(180)                                                                           # waiting the manager to be up
    launch_cluster(KPName, 'm4.large')                                                        # launching worker
    instanceIds.append(launch_instance(KPName, 't2.large', ClusterPrivateIps[-3], 'gate'))    # launching gatekeeper
    time.sleep(60)                                                                            # Waiting until the gatekeeper is up
    proxySg = util.create_sg(ec2_client, 'proxySg', instanceIds[-2][1], 'proxy')              # create security group to allow traffic only from the gatekeeper
    storeIpAddresses(instanceIds[4])
    subprocess.run(['sh', './setProxy.sh'])
    instanceIds.append(launch_instance(KPName, 't2.large', ClusterPrivateIps[-3], 'proxy', proxySg))   # launching proxy

    initiate_gatekeeper(instanceIds[-1][1])                                                  # Initiating the gatekeeper with the proxy public ip as the trusted host
    


    return  instanceIds, KPName
