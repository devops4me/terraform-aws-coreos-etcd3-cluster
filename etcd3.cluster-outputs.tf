
################ ################################################## ########
################ Module [[[security group]]] Output Variables List. ########
################ ################################################## ########

### ##################################### ###
### [[output]] out_load_balancer_dns_name ###
### ##################################### ###

output out_load_balancer_dns_name
{
    value = "${ module.load-balancer.out_dns_name }"
}


### ################################## ###
### [[output]] out_public_ip_addresses ###
### ################################## ###

output out_public_ip_addresses
{
    value = "${ aws_instance.etcd3_node.*.public_ip }"
}


### ################################### ###
### [[output]] out_private_ip_addresses ###
### ################################### ###

output out_private_ip_addresses
{
    value = "${ aws_instance.etcd3_node.*.private_ip }"
}
