variable "azs" { type = "list" }
variable "bastion_ami" {}
variable "dns_support" { default = true }
variable "flow_log_traffic_type" { default = "ALL" }
variable "flowlogrole" {} # Imported from the tfmod-aws-acct module
variable "key_name" {}
variable "my_ip" { default = "" }
variable "network_name" {}
variable "priv_subnet_num" {}
variable "pub_subnet_num" {}
variable "region" {}
variable "subnet_bit" {}
variable "vpc_cidr_block" {}
variable "tags" { default = "" }

resource "aws_vpc" "vpc" {
  cidr_block = "${var.vpc_cidr_block}"
  enable_dns_support = "${var.dns_support}"
  enable_dns_hostnames = true
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
  availability_zone = "${var.azs[count.index]}"
  cidr_block = "${cidrsubnet(var.vpc_cidr_block, var.subnet_bit, count.index)}"
  tags = "${merge(var.tags, map("Name", join(var.network_name,"-pub-", count.index))}"
}

resource "aws_subnet" "priv" {
  count = "${length(var.priv_subnet_num)}"
  vpc_id = "${aws_vpc.vpc.id}"
  availability_zone = "${var.azs[count.index]}"
  cidr_block = "${cidrsubnet(var.vpc_cidr_block, var.subnet_bit, count.index+var.pub_subnet_num)}"
  tags =  "${merge(var.tags, map("Name", join(var.network_name,"-priv-",count.index))}"
  }
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

  tags = "${merge(var.tags, map("Name", join(var.network_name,"-GuardrailNacl"))}"
}

resource "aws_instance" "bastion" {
  ami = "${var.bastion_ami}"
  instance_type = "t2.micro"
  key_name = "${var.key_name}"
  vpc_security_group_ids = [ "${aws_security_group.bastionsg.id}" ]
  subnet_id = "${aws_subnet.pub.*.id[0]}"
  associate_public_ip_address = true
  tags =  "${merge(var.tags, map("Name", join(var.network_name,"-bastion"))}"
}

resource "aws_security_group" "bastionsg" {
  name = "${var.network_name}-bastionsg"
  vpc_id = "${aws_vpc.vpc.id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
}

output "bastion" { value = "${aws_instance.bastion.public_dns}" }
output "bastionsg" { value = "${aws_security_group.bastionsg.id}" }
output "pub_subnets" { value = ["${aws_subnet.pub.*.id}"] }
output "priv_subnets" { value = ["${aws_subnet.priv.*.id}"] }
output "priv_route_table_ids" { value = ["${aws_route_table.priv.*.id}"] }
output "vpc_id" { value = "${aws_vpc.vpc.id}" }
