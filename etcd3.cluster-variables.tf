
################ ######################################## ########
################ Module [[[rules]]] Input Variables List. ########
################ ######################################## ########

### ########################## ###
### [[variable]] in_node_count ###
### ########################## ###

variable in_node_count
{
    description = "The (minimum 3) number of EC2 nodes the etcd3 cluster will be brought up with."
    default     = "3"
}


### ###################### ###
### [[variable]] in_egress ###
### ###################### ###

variable in_egress
{
    description = "4 element list defining traffic to allow out (see traffic-rules.tf)"
    type        = "list"
    default = [ "all-traffic" ]
}
