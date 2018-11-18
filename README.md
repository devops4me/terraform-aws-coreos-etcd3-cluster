
# coreos etcd3 cluster | terraform and ignition

This terraform module uses **ignition** to bring up an **etcd3 cluster** on **CoreOS** in the AWS cloud. It returns you a **single (application) load balancer url** making the cluster accessible for reading, writing and querying using CUrl or a REST API.

Use the Route53 module to put the load balancer Url behind a human readable DNS name.

Usage

    module etcd3_cluster
    {
        source                 = "github.com/devops4me/terraform-aws-etcd3-cluster"
        in_vpc_cidr            = "10.99.0.0/16"
        in_ecosystem           = "etcd3-cluster"
    }

    output etcd3_cluster_url
    {
        value = "${ module.etcd3_cluster.out_etcd3_cluster_url }"
    }

    output etcd3_discovery_url
    {
        value = "${ module.etcd3_cluster.out_etcd3_discovery_url }"
    }

Ignition replaces the legacy cloud init (cloud-config.yaml) as a means of boostrapping CoreOS hence this module uses the **terraform ignition resource** to configure the cluster as the machines come up.

**In only 20 seconds Terraform and Ignition can bring up a 5 node etcd3 cluster inside the AWS cloud.**


## etcd discovery url | python script

Every etcd cluster instance must have a unique discovery url. The discovery url is a service that the nodes contact as they are booting up and it helps them decide who is the leader and also to gain information about the available peers.

In this module Terraform calls a small python script which gets a fresh discovery url every time a new cluster is brought up. The python script takes one parameter which is the number of nodes the cluster contains.

### example python script logs

    20181117 06:39:42 PM [etcd3-discovery-url.py] invoking script to grab an etcd discovery url.
    20181117 06:39:42 PM The stated node count in the etcd cluster is [3]
    20181117 06:39:42 PM Starting new HTTPS connection (1): discovery.etcd.io:443
    20181117 06:39:43 PM https://discovery.etcd.io:443 "GET /new?size=3 HTTP/1.1" 200 58
    20181117 06:39:43 PM The etcd discovery url retrieved is [https://discovery.etcd.io/a660b68aa151605f0ed32807b4be165f]

On each run the python script writes logs into a file called **`etcd3-discovery-url.log`** in the same directory.
