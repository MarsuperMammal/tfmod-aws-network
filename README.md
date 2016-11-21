vpc terraform module
===========

A terraform module to provide a VPC in AWS.


Module Input Variables
----------------------

- `azs` - list of AZs in which to distribute subnets
- `dns_hostnames` - should be true if you want to use private DNS within the VPC
- `dns_support` - should be true if you want to use private DNS within the VPC
- `flow_log_traffic_type` - VPC Flow Log traffic type
- `flowlogrole` - IAM role for VPC Flow Logs
- `network_name` - vpc name
- `pub_subnet_num` - list of public subnet cidrs
- `priv_subnet_num` - list of private subnet cidrs
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
  subnet_bit = "8"
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


Outputs
-----

 - `priv_subnets` - list of private subnet ids
 - `pub_subnets` - list of public route table ids
 - `priv_route_table_ids` - list of private route table ids
 - `vpc_id` - VPC id

Author
=======

Originally created and maintained by [Phil Watts](https://github.com/)

License
=======

Apache 2 Licensed. See LICENSE for full details.
