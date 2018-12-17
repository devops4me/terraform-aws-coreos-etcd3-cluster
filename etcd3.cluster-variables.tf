
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

### ################# ###
### in_ecosystem_name ###
### ################# ###

variable in_ecosystem_name
{
    description = "Creational stamp binding all infrastructure components created on behalf of this ecosystem instance."
}


### ################ ###
### in_tag_timestamp ###
### ################ ###

variable in_tag_timestamp
{
    description = "A timestamp for resource tags in the format ymmdd-hhmm like 80911-1435"
}


### ################## ###
### in_tag_description ###
### ################## ###

variable in_tag_description
{
    description = "Ubiquitous note detailing who, when, where and why for every infrastructure component."
}
