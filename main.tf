variable "azs" { type = "list" }
variable "dns_hostnames" { default = true }
variable "dns_support" { default = true }
variable "flow_log_traffic_type" { default = "ALL" }
variable "flowlogrole" {} # Imported from the tfmod-aws-acct module
variable "map_public_ip_on_launch" {}
variable "network_name" {}
variable "priv_subnet_num" {}
variable "pub_subnet_num" {}
variable "region" {}
variable "subnet_bit" {}
variable "tags" { default = "" }
variable "vpc_cidr_block" {}


resource "aws_vpc" "vpc" {
  cidr_block = "${var.vpc_cidr_block}"
  enable_dns_support = "${var.dns_support}"
  enable_dns_hostnames = "${var.dns_hostnames}"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"
}

resource "aws_cloudwatch_log_group" "log_group" {
  name = "${var.network_name}-aws_vpc_log_group"
}

resource "aws_flow_log" "flow_log" {
  log_group_name = "${aws_cloudwatch_log_group.log_group.name}"
  iam_role_arn = "${var.flowlogrole}"
  vpc_id = "${aws_vpc.vpc.id}"
  traffic_type = "${var.flow_log_traffic_type}"
  depends_on = ["aws_cloudwatch_log_group.log_group"]
}

resource "aws_vpc_endpoint" "s3e" {
  vpc_id = "${aws_vpc.vpc.id}"
  route_table_ids = ["${aws_route_table.priv.*.id}", "${aws_route_table.pub.id}"]
  service_name = "com.amazonaws.${var.region}.s3"
}

resource "aws_subnet" "pub" {
  count = "${var.pub_subnet_num}"
  vpc_id = "${aws_vpc.vpc.id}"
  map_public_ip_on_launch = "${var.map_public_ip_on_launch}"
  availability_zone = "${var.azs[count.index]}"
  cidr_block = "${cidrsubnet(var.vpc_cidr_block, var.subnet_bit, count.index)}"
 }

resource "aws_subnet" "priv" {
  count = "${var.priv_subnet_num}"
  vpc_id = "${aws_vpc.vpc.id}"
  availability_zone = "${var.azs[count.index]}"
  cidr_block = "${cidrsubnet(var.vpc_cidr_block, var.subnet_bit, count.index + var.pub_subnet_num)}"
}

resource "aws_eip" "nat_gateway" {
  count = "${var.pub_subnet_num}"
  vpc = true
}

resource "aws_nat_gateway" "gateway" {
  count = "${var.pub_subnet_num}"
  allocation_id = "${aws_eip.nat_gateway.*.id[count.index]}"
  subnet_id = "${aws_subnet.pub.*.id[count.index]}"
}

resource "aws_route_table" "pub" {
  vpc_id = "${aws_vpc.vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.igw.id}"
  }
}

resource "aws_route_table" "priv" {
  count = "${var.priv_subnet_num}"
  vpc_id = "${aws_vpc.vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.gateway.*.id[count.index]}"
  }
}

resource "aws_route_table_association" "pub" {
  count = "${var.pub_subnet_num}"
  subnet_id = "${aws_subnet.pub.*.id[count.index]}"
  route_table_id = "${aws_route_table.pub.id}"
}

resource "aws_route_table_association" "priv" {
  count = "${var.priv_subnet_num}"
  subnet_id = "${aws_subnet.priv.*.id[count.index]}"
  route_table_id = "${aws_route_table.priv.*.id[count.index]}"
}

resource "aws_network_acl" "guardrail" {
  vpc_id = "${aws_vpc.vpc.id}"
  subnet_ids = [ "${aws_subnet.pub.*.id}", "${aws_subnet.priv.*.id}" ]
  egress {
    protocol = "tcp"
    rule_no = 100
    action = "deny"
    cidr_block =  "0.0.0.0/0"
    from_port = 20
    to_port = 21
  }
  egress {
    protocol = "tcp"
    rule_no = 110
    action = "deny"
    cidr_block =  "0.0.0.0/0"
    from_port = 23
    to_port = 23
  }
  egress {
    protocol = "tcp"
    rule_no = 120
    action = "deny"
    cidr_block =  "0.0.0.0/0"
    from_port = 110
    to_port = 110
  }
  egress {
    protocol = "tcp"
    rule_no = 130
    action = "deny"
    cidr_block =  "0.0.0.0/0"
    from_port = 143
    to_port = 143
  }
  egress {
    protocol = "udp"
    rule_no = 140
    action = "deny"
    cidr_block =  "0.0.0.0/0"
    from_port = 161
    to_port = 162
  }
  egress {
    protocol = "-1"
    rule_no = 32766
    action = "allow"
    cidr_block =  "0.0.0.0/0"
    from_port = 0
    to_port = 0
  }

  ingress {
    protocol = "tcp"
    rule_no = 100
    action = "deny"
    cidr_block =  "0.0.0.0/0"
    from_port = 20
    to_port = 21
  }
  ingress {
    protocol = "tcp"
    rule_no = 110
    action = "deny"
    cidr_block =  "0.0.0.0/0"
    from_port = 23
    to_port = 23
  }
  ingress {
    protocol = "tcp"
    rule_no = 120
    action = "deny"
    cidr_block =  "0.0.0.0/0"
    from_port = 110
    to_port = 110
  }
  ingress {
    protocol = "tcp"
    rule_no = 130
    action = "deny"
    cidr_block =  "0.0.0.0/0"
    from_port = 143
    to_port = 143
  }
  ingress {
    protocol = "udp"
    rule_no = 140
    action = "deny"
    cidr_block =  "0.0.0.0/0"
    from_port = 161
    to_port = 162
  }
  ingress {
    protocol = "-1"
    rule_no = 32766
    action = "allow"
    cidr_block =  "0.0.0.0/0"
    from_port = 0
    to_port = 0
  }
}

output "pub_subnets" { value = ["${aws_subnet.pub.*.id}"] }
output "priv_subnets" { value = ["${aws_subnet.priv.*.id}"] }
output "priv_route_table_ids" { value = ["${aws_route_table.priv.*.id}"] }
output "vpc_id" { value = "${aws_vpc.vpc.id}" }
