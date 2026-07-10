# Existing Security Group

data "aws_security_group" "rke2" {
  name = "${var.cluster_name}-sg"
}