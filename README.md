
# etcd3 cluster creation using Terraform and Ignition

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
