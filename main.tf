data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "vpc" {
  cidr_block = "${var.vpc_cidr_block}"
  enable_dns_support = "${var.dns_support}"
  enable_dns_hostnames = "${var.dns_hostnames}"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = "${aws_vpc.vpc.id}"
}

resource "aws_vpc_endpoint" "s3e" {
  vpc_id = "${aws_vpc.vpc.id}"
  route_table_ids = ["${aws_route_table.priv.*.id}", "${aws_route_table.pub.id}"]
  service_name = "com.amazonaws.${var.region}.s3"
}

resource "aws_subnet" "pub" {
  count = "${length(data.aws_availability_zones.available.names)}"
  vpc_id = "${aws_vpc.vpc.id}"
  map_public_ip_on_launch = "${var.map_public_ip_on_launch}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block = "${cidrsubnet(var.vpc_cidr_block, var.subnet_bit, count.index)}"
}

resource "aws_subnet" "priv" {
  count = "${length(data.aws_availability_zones.available.names)}"
  vpc_id = "${aws_vpc.vpc.id}"
  availability_zone = "${data.aws_availability_zones.available.names[count.index]}"
  cidr_block = "${cidrsubnet(var.vpc_cidr_block, var.subnet_bit, count.index + length(data.aws_availability_zones.available.names))}"
}

resource "aws_eip" "nat_gateway" {
  count = "${length(data.aws_availability_zones.available.names)}"
  vpc = true
}

resource "aws_nat_gateway" "gateway" {
  count = "${length(data.aws_availability_zones.available.names)}"
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
  count = "${length(data.aws_availability_zones.available.names)}"
  vpc_id = "${aws_vpc.vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.gateway.*.id[count.index]}"
  }
}

resource "aws_route_table_association" "pub" {
  count = "${length(data.aws_availability_zones.available.names)}"
  subnet_id = "${aws_subnet.pub.*.id[count.index]}"
  route_table_id = "${aws_route_table.pub.id}"
}

resource "aws_route_table_association" "priv" {
  count = "${length(data.aws_availability_zones.available.names)}"
  subnet_id = "${aws_subnet.priv.*.id[count.index]}"
  route_table_id = "${aws_route_table.priv.*.id[count.index]}"
}

resource "aws_security_group" "bastion_sg" {
  name = "bastion_sg"
  vpc_id = "${aws_vpc.vpc.id}"

  ingress {
    from_port = 22
    to_port = 22
    protocol = "TCP"
    cidr_blocks = ["${var.my_ip}"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "bastion" {
  count = "${var.enable_bastion == "true" ? 1 : 0 }"

  ami           = "${var.bastion_ami}"
  instance_type = "${var.bastion_instance_type}"
  key_name      = "${var.key_name}"
  subnet_id     = "${aws_subnet.pub.*.id[count.index]}"

  vpc_security_group_ids = ["${aws_security_group.bastion_sg.id}"]

  tags {
    Name = "${var.network_name}-bastion"
  }
}

resource "aws_network_acl" "guardrail" {
  count = "${var.enable_guardrail_nacl == true ? 1 : 0 }"
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
