vpc terraform module
===========

A terraform module to provide a VPC in AWS.


Module Input Variables
----------------------

- `dns_hostnames` - should be true if you want to use private DNS within the VPC
- `dns_support` - should be true if you want to use private DNS within the VPC
- `enable_guardrail_nacl` - feature flag variable for including a best practices nacl
- `network_name` - vpc name
- `region` - AWS Region
- `subnet_bit` - bit offset for subnet size
- `tags` - Map variable for standard tags
- `vpc_cidr_block` - vpc cidr

Usage
-----

```hcl
variable "tags" { type = map }
data "aws_availability_zones" "available" {}

data "terraform_remote_state" "acct" {
  backend = "s3"
  config {
    bucket = "unique_remote_state"
    key = "acct.tfstate"
  }
}

module "vpc" {
  source = "github.com/marsupermammal/tfmod-aws-network"
  network_name = "my_network"
  vpc_cidr_block = "10.0.0.0/16"
  priv_subnet_num = "2"
  pub_subnet_num  = "2"
  subnet_bit = "10"
  flowlogrole = "${data.terraform_remote_state.acct.flowlogrole}"
  flow_log_traffic_type = "ALL"
  dns_support = true
  dns_hostnames = true
  region = "us-east-1"
  azs = "${data.aws_availability_zones.available.names}"
  tags = ""
}
```

Idioms
-----
### Count iterating over a list

```hcl
resource "aws_subnet" "pub" {
  count = "${length(data.aws_availability_zones.available.names)}"
  availability_zone = "${var.azs[count.index]}"
  ...
}
```

### CIDR block allocation
In this example the cidr blocks for subnets are defined by the vpc_cidr_block variable, and the use of the cidrsubnet intepolation syntax.

```hcl
resource "aws_subnet" "pub" {
  count = "${length(data.aws_availability_zones.available.names)}"
  cidr_block = "${cidrsubnet(var.vpc_cidr_block, var.subnet_bit, count.index)}"
}
```

```
If vpc_cidr_block = 172.16.0.0/16, pub_subnet_num = 4 and the desired subnets would have a /26 network mask then;
aws_subnet.pub.0.cidr_block = 172.16.0.0/26
aws_subnet.pub.1.cidr_block = 172.16.0.64/26
aws_subnet.pub.2.cidr_block = 172.16.0.128/26
aws_subnet.pub.3.cidr_block = 172.16.0.192/26
```

### Setting Module defined tags along with a tagging standard
Since the addition of map variable types in Terraform 0.7, this pattern has been made possible for setting specific modules tags while using a company wide tagging standard.

```hcl
variable "tags" { type = "map" }
variable "network_name" { default = "my_network" }

resource "aws_subnet" "pub" {
  count = "${length(data.aws_availability_zones.available.names)}"
  tags = "${merge(var.tags, map("Name", join(var.network_name,"-pub-", count.index))}"
}
```

```
Given:
# terraform.tfvars
tags = {
  Owner = "Phil"
  Cost_Center = "012345"
}

aws_subnet.pub.0 would have the following tags.

tags {
  Name = my_network-pub-0
  Owner = Phil
  Cost_Center = 012345
}
```



Outputs
-----

 - `priv_subnets` - list of private subnet ids
 - `pub_subnets` - list of public subnet
 - `vpc_id` - VPC id

Author
=======

Originally created and maintained by [Phil Watts](https://github.com/)

License
=======

Apache 2 Licensed. See LICENSE for full details.
