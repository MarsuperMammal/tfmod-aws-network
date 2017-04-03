variable "dns_hostnames" { default = true }
variable "dns_support" { default = true }
variable "flow_log_traffic_type" { default = "ALL" }
variable "flowlogrole" {} # Imported from the tfmod-aws-acct module
variable "map_public_ip_on_launch" {}
variable "network_name" {}
variable "region" {}
variable "subnet_bit" {}
variable "tags" { default = "" }
variable "vpc_cidr_block" {}