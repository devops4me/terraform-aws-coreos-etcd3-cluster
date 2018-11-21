
### ############################################################## ###
### [[etcd3-cluster-module]] bring up etcd3 cluster using ignition ###
### ############################################################## ###

locals
{
    ecosystem_id = "etcd3-cluster"
    discovery_url = "${ data.external.etcd_url.result[ "etcd_discovery_url" ] }"

    ignition_etcd3_json_content = "[Unit]\nRequires=coreos-metadata.service\nAfter=coreos-metadata.service\n\n[Service]\nEnvironmentFile=/run/metadata/coreos\nExecStart=\nExecStart=/usr/lib/coreos/etcd-wrapper $ETCD_OPTS \\\n  --listen-peer-urls=\"http://$${COREOS_EC2_IPV4_LOCAL}:2380\" \\\n  --listen-client-urls=\"http://0.0.0.0:2379\" \\\n  --initial-advertise-peer-urls=\"http://$${COREOS_EC2_IPV4_LOCAL}:2380\" \\\n  --advertise-client-urls=\"http://$${COREOS_EC2_IPV4_LOCAL}:2379\" \\\n  --discovery=\"${local.discovery_url}\""
}


# @@@@@@@@@@@@@@@@@@@@@
# @@@@@@@@@@@@@@@@@@@@@
# @@@@@@@@@@@@@@@@@@@@@
resource aws_key_pair troubleshoot
{
    key_name = "etcd3-cluster-keypair"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCXogeVepMAwZVBusFkHBabnLLL9NiYI0UgsxbqU8D5H+aMwOcZXiZyJSMvfgGQlkhFQidR3vhUcxmUA4LGlSHnEeiO7g7hgx5bb+nMI4RLXHzOh9BalsCEcZwFMAYAC2108EFLLflUMmIYe57XN/M/R6ct7pZAitIdEJ5/VpVTJ6P2Vj7Rt8BKn/p3bMy9l7CUcs/EmG/avxZ2ykK2bMl66l4fVE2r+vLqHLCUw+r6GtwTfeuT1iofhTp0ar82Pb3it+oSb7P2Kesq7AG6HpWHoyjQoQk+isTzdMrJ6ackIoYqZwol3wTSzx66QZmE8+KqODT/We7y1LqAMKOqa2tp"
}


# = ===
# = Run a bash script which only contains a curl command to retrieve
# = the etcd discovery url from the service offered by CoreOS.
# = This is how to retrieve the URL from any command line.
# = ===
# = $ curl https://discovery.etcd.io/new?size=3
# = ===
data external etcd_url
{
    program = [ "python", "${path.module}/etcd3-discovery-url.py", "${ var.in_node_count }" ]
}


# = ===
# = This EC2 instance bootsrap configured by ignition is the engine room
# = that powers the etcd3 cluster running within the CoreOS machine.
# = ===
resource aws_instance etcd3_node
{
    count = "3"

    instance_type          = "t2.medium"
    ami                    = "${ module.coreos_ami_id.out_ami_id }"
    subnet_id              = "${ element( module.vpc-subnets.out_private_subnet_ids, count.index ) }"
    user_data              = "${ data.ignition_config.etcd3.rendered }"
    vpc_security_group_ids = [ "${ module.security-group.out_security_group_id }" ]

# @@@@@@@@@@@@@@@@@@@@@
# @@@@@@@@@@@@@@@@@@@@@
    key_name               = "${ aws_key_pair.troubleshoot.id }"


    tags
    {
        Name   = "ec2-0${ ( count.index + 1 ) }-${ local.ecosystem_id }-${ module.ecosys.out_stamp }"
        Class = "${ local.ecosystem_id }"
        Instance = "${ local.ecosystem_id }-${ module.ecosys.out_stamp }"
        Desc   = "This etcd3 ec2 node no.${ ( count.index + 1 ) } for ${ local.ecosystem_id } ${ module.ecosys.out_history_note }"
    }

}


# = ===
# = Visit the terraform ignition user manual at the url below to
# = understand how ignition is used as the de-factor cloud-init
# = starter for a cluster of CoreOS machines.
# = ===
# = https://www.terraform.io/docs/providers/ignition/index.html
# = ===
data ignition_config etcd3
{
    systemd = [
        "${data.ignition_systemd_unit.etcd3.id}",
    ]
}


# = ===
# = This slice of the ignition configuration deals with the
# = systemd service. Once rendered it is then placed alongside
# = the other ignition configuration blocks in ignition_config
# = ===
data ignition_systemd_unit etcd3
{
    name = "etcd-member.service"
    enabled = "true"
    dropin
    {
        name = "20-clct-etcd-member.conf"
        content = "${ local.ignition_etcd3_json_content }"
    }

}


# = ===
# = Thist state-of-the-art AWS application load balancer will service
# = etcd traffic on port 2379 while round robin spraying the clustered
# = nodes via the private IP addresses.
# =
# = Fow neither certificates nor the secure SSL protocol are used so
# = this simple setup is mainly for development and testing purposes.
# = ===
module load-balancer
{
    source               = "github.com/devops4me/terraform-aws-load-balancer"
    in_vpc_id            = "${ module.vpc-subnets.out_vpc_id }"
    in_subnet_ids        = "${ module.vpc-subnets.out_public_subnet_ids }"
    in_security_group_id = "${ module.security-group.out_security_group_id }"
    in_ip_addresses      = "${ aws_instance.etcd3_node.*.private_ip }"
    in_ip_address_count  = 3
    in_front_end         = [ "web"  ]
    in_back_end          = [ "etcd" ]
    in_is_internal       = false
    in_ecosystem         = "${ local.ecosystem_id }"
}


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
#########    in_ingress     = [ "ssh", "http" ]
    in_ingress     = [ "ssh", "http", "https", "etcd-client", "etcd-server", "etcd-listen" ]
    in_vpc_id      = "${ module.vpc-subnets.out_vpc_id }"
    in_use_default = "true"
    in_ecosystem   = "${ local.ecosystem_id }"
}


# = ===
# = This module dynamically acquires the HVM CoreOS AMI ID for the region that
# = this infrastructure is built in (specified by the AWS credentials in play).
# = ===
module coreos_ami_id
{
    source = "github.com/devops4me/terraform-aws-coreos-ami-id"
}


# = ===
# = Build the eco-system string identifier and a history note detailing the
# = who, why, what, when and where.
# = ===
module ecosys
{
    source = "github.com/devops4me/terraform-aws-stamps"
}



# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
# @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


resource aws_instance bastion_node
{
    count = "3"

    ami                    = "${ data.aws_ami.ubuntu1804.id }"
    instance_type          = "t2.medium"
    vpc_security_group_ids = [ "${ module.security-group.out_security_group_id }" ]

    subnet_id              = "${ element( module.vpc-subnets.out_public_subnet_ids, count.index ) }"
    key_name               = "${ aws_key_pair.troubleshoot.id }"

    tags
    {
        Name   = "bastion-0${ ( count.index + 1 ) }-${ local.ecosystem_id }-${ module.ecosys.out_stamp }"
        Class = "${ local.ecosystem_id }"
        Instance = "${ local.ecosystem_id }-${ module.ecosys.out_stamp }"
        Desc   = "This bastion ec2 node no.${ ( count.index + 1 ) } for ${ local.ecosystem_id } ${ module.ecosys.out_history_note }"
    }



}


output out_bastion_public_ip_addresses
{
    value = "${ aws_instance.bastion_node.*.public_ip }"
}



    data aws_ami ubuntu1804
    {
        most_recent = true

        filter
        {
            name   = "name"
            values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
        }

        filter
        {
            name   = "virtualization-type"
            values = [ "hvm" ]
        }

        owners = ["099720109477"]
    }
