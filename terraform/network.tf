data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# We just need one subnet to launch both nodes into for a simple demo cluster
data "aws_subnet" "chosen" {
  id = tolist(data.aws_subnets.default.ids)[0]
}
