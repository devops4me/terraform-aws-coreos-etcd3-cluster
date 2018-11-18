
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


## etcd cluster load balancer url

This module places a load balancer in front of the etcd node cluster and provides it as an output. Use CUrl or the etcd REST API through this load balancer URL to converse with the cluster.




## etcd discovery url | python script

Every etcd cluster instance must have a unique discovery url. The discovery url is a service that the nodes contact as they are booting up and it helps them decide who is the leader and also to gain information about the available peers.

In this module Terraform calls a small python script which gets a fresh discovery url every time a new cluster is brought up. The python script takes one parameter which is the number of nodes the cluster contains.

### python script logs | discovery url

After a successful run visit file **`etcd3-discovery-url.log`** and the discovery url will be on the last line within square brackets.

    20181118 06:29:37 PM [etcd3-discovery-url.py] invoking script to grab an etcd discovery url.
    20181118 06:29:37 PM The stated node count in the etcd cluster is [3]
    20181118 06:29:37 PM Starting new HTTPS connection (1): discovery.etcd.io:443
    20181118 06:29:38 PM https://discovery.etcd.io:443 "GET /new?size=3 HTTP/1.1" 200 58
    20181118 06:29:38 PM The etcd discovery url retrieved is [https://discovery.etcd.io/9a69d64726338dabf0a279d4fa7e803e]

Visit the discovery url and the resultant JSON should be like the below.

#### Discovery URL JSON

Note that the JSON returned (when pretty-fied) shows the private IP addresses of the ec2 nodes as per the ignition script.

{
   "action":"get",
   "node":{
      "key":"/_etcd/registry/9a69d64726338dabf0a279d4fa7e803e",
      "dir":true,
      "nodes":[
         {
            "key":"/_etcd/registry/9a69d64726338dabf0a279d4fa7e803e/38cebe7031d3d519",
            "value":"741452a8c5544c7b9d93339dd98d3870=http://10.66.44.247:2380",
            "modifiedIndex":1509771734,
            "createdIndex":1509771734
         },
         {
            "key":"/_etcd/registry/9a69d64726338dabf0a279d4fa7e803e/968d216a6ef51a51",
            "value":"9a011e178ed544cd8e23d46a0c1d23c4=http://10.66.25.217:2380",
            "modifiedIndex":1509771735,
            "createdIndex":1509771735
         },
         {
            "key":"/_etcd/registry/9a69d64726338dabf0a279d4fa7e803e/39beec7eb77a8a4",
            "value":"8f0e7d5107f947d0b1ba5e6485af1c01=http://10.66.11.142:2380",
            "modifiedIndex":1509771771,
            "createdIndex":1509771771
         }
      ],
      "modifiedIndex":1509771563,
      "createdIndex":1509771563
   }
}