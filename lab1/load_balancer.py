import boto3
import util

def create_lb_listener(subnets, ec2_client, elb_client, sgId=None):

    vpc = util.fetch_vpc(ec2_client)

    # create target group
    def create_tg(name, VpcId):
        response = elb_client.create_target_group(Name=name, Protocol='HTTP', ProtocolVersion='HTTP1', Port=80, VpcId=VpcId,
                                                  HealthCheckProtocol='HTTP', HealthCheckEnabled=True)

        return response['TargetGroups'][0]['TargetGroupArn']

    # launching load balancer
    def launch_lb():
        load_balancer = elb_client.create_load_balancer(
                            Name = 'LoadBalancer',
                            Subnets = subnets,
                            SecurityGroups = [sgId]
                        )

        return load_balancer['LoadBalancers'][0]['LoadBalancerArn'], load_balancer['LoadBalancers'][0]['DNSName']


    # creating routing rule
    def create_rule(listenerArn, route, TGArn, priority):
        response = elb_client.create_rule( 
                    ListenerArn = listenerArn, 
                    Actions =[{'Type': 'forward', 'TargetGroupArn': TGArn}], 
                    Conditions =[{ 'Field':'path-pattern', 'Values':[route]}],
                    Priority = priority
                    )
        return response['Rules'][0]['RuleArn']
    
    tg1Arn = create_tg('cluster1-1', vpc)
    tg2Arn = create_tg('cluster2-2', vpc)
    lbArn, lbDNS = launch_lb()

    # creating load balancer listener
    listener = elb_client.create_listener(
                    LoadBalancerArn = lbArn,
                    Protocol = 'HTTP',
                    Port = 80,
                    DefaultActions = [{'Type': 'forward', 'TargetGroupArn': tg1Arn, 'Order': 1}]
                )
    
    listenerArn = listener['Listeners'][0]['ListenerArn']

    create_rule(listenerArn, '/1', tg1Arn, 1)
    create_rule(listenerArn, '/2', tg2Arn, 2)

    return  lbArn, tg1Arn, tg2Arn, lbDNS