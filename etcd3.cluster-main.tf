
### ############################################################## ###
### [[etcd3-cluster-module]] bring up etcd3 cluster using ignition ###
### ############################################################## ###

locals
{
    ecosystem_id = "etcd3-cluster"
    discovery_url = "${ data.external.etcd_url.result[ "etcd_discovery_url" ] }"

    ignition_etcd3_json_content = "[Unit]\nRequires=coreos-metadata.service\nAfter=coreos-metadata.service\n\n[Service]\nEnvironmentFile=/run/metadata/coreos\nExecStart=\nExecStart=/usr/lib/coreos/etcd-wrapper $ETCD_OPTS \\\n  --listen-peer-urls=\"http://$${COREOS_EC2_IPV4_LOCAL}:2380\" \\\n  --listen-client-urls=\"http://0.0.0.0:2379\" \\\n  --initial-advertise-peer-urls=\"http://$${COREOS_EC2_IPV4_LOCAL}:2380\" \\\n  --advertise-client-urls=\"http://$${COREOS_EC2_IPV4_LOCAL}:2379\" \\\n  --discovery=\"${local.discovery_url}\""

    public_key_content = "ssh-rsa AAAABasdasdfasdfadfljiasdfa34324jh2f34hjgfjasdfasdfad"
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
resource aws_instance node
{
    count = "3"

    instance_type          = "t2.micro"
    ami                    = "${ module.coreos_ami_id.out_ami_id }"
###########    key_name               = "${ aws_key_pair.troubleshoot.id }"
    subnet_id              = "${ element( module.vpc-subnets.out_subnet_ids, count.index ) }"
    user_data              = "${ data.ignition_config.etcd3.rendered }"
    vpc_security_group_ids = [ "${ module.security-group.out_security_group_id }" ]

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
# = This public key enables logging into any of the nodes
# = that should be running etcd3 for troubleshooting and
# = validation purposes.
# = ===
resource aws_key_pair troubleshoot
{
    count = "0"
    key_name = "etcd3-cluster-keypair"
    public_key = "${ local.public_key_content }"
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
    in_subnet_ids        = "${ module.vpc-subnets.out_subnet_ids }"
    in_security_group_id = "${ module.security-group.out_security_group_id }"
    in_ip_addresses      = "${ aws_instance.node.*.private_ip }"
    in_ip_address_count  = 3
    in_listeners         = [ "web"  ]
    in_targets           = [ "etcd" ]
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
