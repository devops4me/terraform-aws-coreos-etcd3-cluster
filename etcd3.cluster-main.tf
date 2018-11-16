
### ################################################### ###
### [[test-module]] testing terraform-aws-load-balancer ###
### ################################################### ###

# = ===
# = Test the modern state-of-the-art AWS application load balancer by creating
# = a number of ec2 instances configured with cloud config and set up to serve
# = web pages using either the HTTP or HTTPS protocols.
# =
# = The ec2 instances are placed in a subnets across each of the region's
# = availability zones and the security group is set to allow the appropriate
# = traffic to pass through.
# = ===
/*
module load-balancer-test
{
    source                 = "github.com/devops4me/terraform-aws-load-balancer"
    in_vpc_id            = "${ module.vpc-subnets.out_vpc_id }"
    in_subnet_ids        = "${ module.vpc-subnets.out_subnet_ids }"
    in_security_group_id = "${ module.security-group.out_security_group_id }"
    in_ip_addresses      = "${ aws_instance.server.*.private_ip }"
    in_ip_address_count  = 3
    in_ecosystem         = "${ local.ecosystem_id }"
}
*/

# = ===
# = This module creates a VPC and then allocates subnets in a round robin manner
# = to each availability zone. For example if 8 subnets are required in a region
# = that has 3 availability zones - 2 zones will hold 3 subnets and the 3rd two.
# =
# = Whenever and wherever public subnets are specified, this module knows to create
# = an internet gateway and a route out to the net.
# = ===
module vpc-subnets
{
    source                 = "github.com/devops4me/terraform-aws-vpc-subnets"
    in_vpc_cidr            = "10.66.0.0/16"
    in_num_private_subnets = 0
    in_num_public_subnets  = 3
    in_ecosystem           = "${local.ecosystem_id}"
}


# = ===
# = The security group needs to allow ssh for troubleshooting logins
# = and http plus https to test the load balancers viability against
# = a fleet of web servers.
# = ===
module security-group
{
    source         = "github.com/devops4me/terraform-aws-security-group"
    in_ingress     = [ "ssh", "http", "https", "etcd-client", "etcd-server", "etcd-listen" ]
    in_vpc_id      = "${ module.vpc-subnets.out_vpc_id }"
    in_use_default = "true"
    in_ecosystem   = "${ local.ecosystem_id }"
}


locals
{
    ecosystem_id = "etcd3-cluster"
}


/*
output dns_name{ value             = "${ module.load-balancer-test.out_dns_name}" }
*/

output public_ip_addresses{ value  = "${ aws_instance.server.*.public_ip }" }
output private_ip_addresses{ value = "${ aws_instance.server.*.private_ip }" }




/*
data ignition_systemd_unit example
{
    name = "example.service"
    content = "[Service]\nType=oneshot\nExecStart=/usr/bin/echo Hello World\n\n[Install]\nWantedBy=multi-user.target"
}
*/



# = ===
# = Visit the terraform ignition user manual at the url below to
# = understand how ignition is used as the de-factor cloud-init
# = starter for a cluster of CoreOS machines.
# = ===
# = https://www.terraform.io/docs/providers/ignition/index.html
# = ===
data ignition_config example
{
    systemd = [
        "${data.ignition_systemd_unit.example.id}",
    ]
}



data ignition_systemd_unit example
{
    name = "etcd-member.service"
    enabled = "true"
    dropin
    {
        name = "20-clct-etcd-member.conf"
        content = "[Unit]\nRequires=coreos-metadata.service\nAfter=coreos-metadata.service\n\n[Service]\nEnvironmentFile=/run/metadata/coreos\nExecStart=\nExecStart=/usr/lib/coreos/etcd-wrapper $ETCD_OPTS \\\n  --listen-peer-urls=\"http://$${COREOS_EC2_IPV4_LOCAL}:2380\" \\\n  --listen-client-urls=\"http://0.0.0.0:2379\" \\\n  --initial-advertise-peer-urls=\"http://$${COREOS_EC2_IPV4_LOCAL}:2380\" \\\n  --advertise-client-urls=\"http://$${COREOS_EC2_IPV4_LOCAL}:2379\" \\\n  --discovery=\"https://discovery.etcd.io/2291edd0c764191c26c9969453db2b39\""
    }

}

resource aws_key_pair troubleshoot
{
    key_name = "etcd3-cluster-keypair"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCXogeVepMAwZVBusFkHBabnLLL9NiYI0UgsxbqU8D5H+aMwOcZXiZyJSMvfgGQlkhFQidR3vhUcxmUA4LGlSHnEeiO7g7hgx5bb+nMI4RLXHzOh9BalsCEcZwFMAYAC2108EFLLflUMmIYe57XN/M/R6ct7pZAitIdEJ5/VpVTJ6P2Vj7Rt8BKn/p3bMy9l7CUcs/EmG/avxZ2ykK2bMl66l4fVE2r+vLqHLCUw+r6GtwTfeuT1iofhTp0ar82Pb3it+oSb7P2Kesq7AG6HpWHoyjQoQk+isTzdMrJ6ackIoYqZwol3wTSzx66QZmE8+KqODT/We7y1LqAMKOqa2tp"
}

# = ===
# = Visit cloud-config.yaml and / or the cloud-init url to
# = understand the setup of the web servers.
# = ===
# = https://cloudinit.readthedocs.io/en/latest/index.html
# = ===
resource aws_instance server
{
    count = "3"

    instance_type          = "t2.micro"
    ami                    = "${ module.coreos_ami_id.out_ami_id }"
    key_name               = "${ aws_key_pair.troubleshoot.id }"
    subnet_id              = "${ element( module.vpc-subnets.out_subnet_ids, count.index ) }"
    user_data              = "${ data.ignition_config.example.rendered }"
    vpc_security_group_ids = [ "${ module.security-group.out_security_group_id }" ]

    tags
    {
        Name   = "ec2-0${ ( count.index + 1 ) }-${ local.ecosystem_id }-${ module.ecosys.out_stamp }"
        Class = "${ local.ecosystem_id }"
        Instance = "${ local.ecosystem_id }-${ module.ecosys.out_stamp }"
        Desc   = "This ec2 instance no.${ ( count.index + 1 ) } for ${ local.ecosystem_id } ${ module.ecosys.out_history_note }"
    }

}


# = ===
# = This module dynamically acquires the HVM CoreOS AMI ID for the region that
# = this infrastructure is built in (specified by the AWS credentials in play).
# = ===
module coreos_ami_id
{
    source = "github.com/devops4me/terraform-aws-coreos-ami-id"
}


### ################# ###
### [[module]] ecosys ###
### ################# ###

module ecosys
{
    source = "github.com/devops4me/terraform-aws-stamps"
}
