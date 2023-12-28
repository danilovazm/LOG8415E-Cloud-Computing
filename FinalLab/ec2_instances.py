import boto3
import subprocess, pprint, time
import util

def EC2_instances(ec2_client, sgId):
    instanceIds = []
    amiId = 'ami-06aa3f7caf3a30282' #Os image that will be used in the vm
    ClusterPrivateIps = ['172.31.2.3', '172.31.2.4', '172.31.2.5', '172.31.2.2']
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
    
    def launch_Mgm():
        with open("Mgm-node2.sh", "r") as file:
            script = file.read()
        return script
    
    # ec2 instance launcher
    def launch_instance(KPName, Itype, privateIp,role = 0):
        response = ec2_client.run_instances(
                    PrivateIpAddress=privateIp,
                    SubnetId='subnet-0facea78a1e94b6cd',
                    ImageId=amiId,
                    MinCount=1,
                    MaxCount=1,
                    InstanceType=Itype,
                    KeyName=KPName,
                    SecurityGroupIds=[sgId],
                    UserData=launch_Mgm() if role == 1 else launch_worker() # passing the loaded bash script to the instance
        )
        '''ec2 = boto3.resource('ec2')
        id = response['Instances'][0]['InstanceId']
        instance = ec2.Instance(id)
        instance.wait_until_running()
        instance.reload()
        
        pprint.pprint(instance.public_ip_address)
        return id, instance.public_ip_address'''
        return id

    # launch the diffent set of instances
    def launch_cluster(KPName, type):
        for i in range(3):
            instanceIds.append(launch_instance(KPName, type, ClusterPrivateIps[i]))

    # store ip adress of instances in files
    def storeIpAddresses(instanceIds):
        for i in range(4):
            with open(f"ip{i+1}.txt", "w") as file:
                file.write(instanceIds[i][1])
            

    # creating key pair and lauching the instances
    KPName = create_key_pair('3rd-assign-key')
    instanceIds.append(launch_instance(KPName, 't2.micro', ClusterPrivateIps[-1], 1))
    time.sleep(180)
    launch_cluster(KPName, 'm4.large')

    # store ip adresses of workers
    #storeIpAddresses(instanceIds)

    # run the orchestrator script 
    #result = subprocess.run(['sh', './orchestrator.sh'])
    


    return  instanceIds, KPName
