# Existing VPC

data "aws_vpc" "cluster" {
  id = "vpc-022e2897645b0d70c"
}

# Existing subnets

data "aws_subnets" "cluster" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.cluster.id]
  }
}

# Use one subnet for EC2

data "aws_subnet" "chosen" {
  id = "subnet-0b41b1fd1f13b8824"
}