variable "dns_hostnames" { default = true }
variable "dns_support" { default = true }
variable "flow_log_traffic_type" { default = "ALL" }
variable "flowlogrole" {} # Imported from the tfmod-aws-acct module
variable "map_public_ip_on_launch" { default = true }
variable "network_name" {}
variable "region" {}
variable "subnet_bit" {}
variable "tags" { default = "" }
variable "vpc_cidr_block" {}

output "priv_subnets" { value = ["${aws_subnet.priv.*.id}"] }
output "pub_subnets" { value = ["${aws_subnet.pub.*.id}"] }
output "vpc_id" { value = "${aws_vpc.vpc.id}" }
output "priv_route_table_ids" { value = ["${aws_route_table.priv.*.id}"] }
