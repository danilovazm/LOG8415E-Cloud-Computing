import boto3
import time

# fetching default vpc
def fetch_vpc(ec2_client = None):
    if not ec2_client:
        ec2_client = boto3.client('ec2', region_name = "us-east-1")
    
    return ec2_client.describe_vpcs()['Vpcs'][0]['VpcId']

# fetching 1 subnet id per availability zone
def fetch_subnet(ec2_client, avZones):
    subnets = []
    for zone in avZones:
        response = ec2_client.describe_subnets(
                            Filters=[{
                                'Name': 'availabilityZone',
                                'Values': [zone]
                            }])
        subnets.append(response['Subnets'][0]['SubnetId'])
    return subnets

# creating security group
def create_sg(ec2_client, sc1_name='2nd-Tp-sg'):
    ec2_resource = boto3.resource('ec2', region_name = "us-east-1")
    sg1_id = ec2_resource.create_security_group(
                        Description='1st cluster security group1',
                        GroupName=sc1_name,
                        VpcId=fetch_vpc())


    # creating inbound rule, authorizing every port and protocol
    ec2_client.authorize_security_group_ingress(
            GroupId=sg1_id.group_id,
            IpProtocol='-1',    
            FromPort=0,          
            ToPort=65535,       
            CidrIp='0.0.0.0/0' 
        )

    return sg1_id.group_id


# terminating instance
def shut_down_instances(ec2_client, instances):
    ids = [i[0] for i in instances]
    ec2_client.terminate_instances(
        InstanceIds = ids
    )

    return

# terminating load balancer and target groups
def shut_down_load_balancer(elb_client, lbArn, tg1Arn, tg2Arn):
    elb_client.delete_load_balancer(LoadBalancerArn=lbArn)
    time.sleep(60)
    elb_client.delete_target_group(TargetGroupArn=tg1Arn)
    elb_client.delete_target_group(TargetGroupArn=tg2Arn)
    return

# deleting security key
def delete_security_group(ec2_client, sgId):
    ec2_client.delete_security_group(GroupId=sgId)
    return

# deleting key pair
def delete_key_pair(ec2_client, KPName):
    ec2_client.delete_key_pair(KeyName=KPName)
    return