
################ ################################################## ########
################ Module [[[security group]]] Output Variables List. ########
################ ################################################## ########

### ##################################### ###
### [[output]] out_load_balancer_dns_name ###
### ##################################### ###

output out_security_group_id
{
    description = "The string ID of either the default security group or the just created new one."
    value       = "${ var.in_use_default ? aws_default_security_group.default.id : aws_security_group.new.id }"
}


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
    value = "${ aws_instance.node.*.public_ip }"
}


### ################################### ###
### [[output]] out_private_ip_addresses ###
### ################################### ###

output out_private_ip_addresses
{
    value = "${ aws_instance.node.*.private_ip }"
}
