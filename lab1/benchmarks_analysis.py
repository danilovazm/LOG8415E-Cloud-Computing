from datetime import datetime, timedelta
import json
import boto3
import pandas as pd
import matplotlib.pyplot as plt

class BenchmarksAnalysis:

    def __init__(self, elb_id, cluster_t2_id, cluster_m4_id, cluster_t2_instances_ids, cluster_m4_instances_ids):
        """Initiate MetricGenerator and print ELB and Cluster IDs."""
        self.cloudwatch = boto3.client('cloudwatch')
        self.elb_id = elb_id
        self.cluster_t2_id = cluster_t2_id
        self.cluster_m4_id = cluster_m4_id        
        self.cluster_t2_instances_ids = cluster_t2_instances_ids
        self.cluster_m4_instances_ids = cluster_m4_instances_ids

        # Instance metrics to be retrieved from CloudWatch
        self.metrics_instances = ['CPUUtilization']

        # Load balancer metrics to be retrieved from CloudWatch
        self.metrics_stat = {
            'HTTPCode_ELB_2XX_Count': 'Sum', #number of HTTP 2XX client error codes that originate from the load balancer
            'HTTPCode_ELB_4XX_Count': 'Sum', #number of HTTP 4XX client error codes that originate from the load balancer
            'HTTPCode_ELB_5XX_Count': 'Sum', #number of HTTP 5XX server error codes that originate from the load balancer
            'RequestCountPerTarget': 'Sum', #average number of request per target
            'TargetResponseTime': 'Average', #time after the request leaves the load balancer until a response from the target is received
            'HTTPCode_Target_2XX_Count': 'Sum', #number of HTTP response codes generated by the targets
            'HTTPCode_Target_4XX_Count': 'Sum',
        }

        # Cluster and Load Balancer metrics to be retrieved from CloudWatch
    def get_metric_data(self):
        # Get all metrics that contain elb_id
        metrics_ELB = [m for m in self.cloudwatch.list_metrics()['Metrics'] if any(True for dim in m['Dimensions'] if self.elb_id in dim.values())]

        # Get all metrics that contain cluster_t2_id
        metrics_T2 = [m for m in self.cloudwatch.list_metrics()['Metrics'] if any(True for dim in m['Dimensions'] if self.cluster_t2_id in dim.values())]

        # Get all metrics that contain cluster_m4_id
        metrics_M4 = [m for m in self.cloudwatch.list_metrics()['Metrics'] if any(True for dim in m['Dimensions'] if self.cluster_m4_id in dim.values())]

        # Combine metrics and remove duplicates
        metrics = metrics_ELB + metrics_T2 + metrics_M4
        metrics = [i for n, i in enumerate(metrics) if i not in metrics[n + 1:]]

        # Build the queries to specify which instance metric data to retrieve
        metric_queries = []
        for id, metric in enumerate(metrics):
            metric_queries.append({
                    'Id': f'metric_{id}',
                    'MetricStat': {
                        'Metric': metric,
                        'Period': 60,
                        'Stat': self.metrics_stat[metric['MetricName']]
                    }
                })

        # Retrieve the data from CloudWatch
        response = self.cloudwatch.get_metric_data(
            MetricDataQueries=metric_queries,
            StartTime=datetime.utcnow() - timedelta(minutes=60),
            EndTime=datetime.utcnow()
        )

        data_cluster = response["MetricDataResults"]

        return data_cluster

        #Generate plots from the data provided by CloudWatch
    def generate_plots(self):

        plt.rcParams["figure.figsize"] = 12,5
        for metric in get_metric_data():
            # Convert dictionary data into pandas
            df = pd.DataFrame.from_dict(metric)[["Timestamps","Values"]]

            if len(df) == 0:
                print(f"ERROR: No datapoints were found for metric {metric['Id']}")

            # Rename columns
            df.rename(columns={'Values': 'Cluster?'}, inplace=True)

            # Parse strings to datetime type
            df["Timestamps"] = pd.to_datetime(df["Timestamps"], infer_datetime_format=True)
            
            # Create plot with matplotlib and save it
            if len(df)!=0:
                print(f"drawing plot {metric['Id']}")
                plt.figure()
                plt.xlabel("Timestamps")
                plt.plot("Timestamps", "Cluster?", color="red", data=df)
                plt.title(metric['Label'].split(' ')[-1])
                handles, labels = plt.gca().get_legend_handles_labels()
                by_label = dict(zip(labels, handles))
                plt.legend(by_label.values(), by_label.keys())
                plt.savefig(f"plots/{metric['Id']}")      
            