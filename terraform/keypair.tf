resource "tls_private_key" "rke2" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

data "aws_key_pair" "rke2" {
  key_name = "yousma-rke2-cluster-new"
}