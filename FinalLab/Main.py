import boto3
import time
import util
import subprocess
import web_requests
import ec2_instances
from paramiko.pkey import Pkey


def main():
    # Initializing clients for EC2 service
    ec2_client = boto3.client('ec2', region_name = "us-east-1")
    print("client connected")

    # create security zone
    sgId = util.create_sg(ec2_client)
    print("client connected")

    # Launch 3 workers and 1 manager of type m4 large
    instancesIds, KPName = ec2_instances.EC2_instances(ec2_client, sgId)
    key = Pkey.from_private_key_file('3rd-assign-key.pem')

    return

main()

