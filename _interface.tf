variable "dns_hostnames" { default = true }
variable "dns_support" { default = true }
variable "map_public_ip_on_launch" { default = true }
variable "network_name" {}
variable "region" {}
variable "subnet_bit" {}
variable "tags" { default = "" }
variable "vpc_cidr_block" {}
variable "enable_guardrail_nacl" { default = true }
variable "enable_bastion" { default = true }
variable "key_name" {}
variable "bastion_ami" {}
variable "bastion_instance_type" { default = "t2.micro" }
variable "my_ip" {}

output "bastion" { value = "${coalesce(aws_instance.bastion.public_dns, "No Bastion Provisioned")}"}
output "priv_subnets" { value = ["${aws_subnet.priv.*.id}"] }
output "pub_subnets" { value = ["${aws_subnet.pub.*.id}"] }
output "vpc_id" { value = "${aws_vpc.vpc.id}" }
