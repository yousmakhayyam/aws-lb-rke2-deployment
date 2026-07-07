# ✅ Data source (existing security group)
data "aws_security_group" "rke2" {
  name = "${var.cluster_name}-sg"
}

# ✅ Security group rules (existing group mein add karo)
resource "aws_security_group_rule" "ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = data.aws_security_group.rke2.id
  description       = "SSH from anywhere (temporary for GitHub Actions)"
}

resource "aws_security_group_rule" "k8s_api" {
  type              = "ingress"
  from_port         = 6443
  to_port           = 6443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = data.aws_security_group.rke2.id
  description       = "Kubernetes API"
}

resource "aws_security_group_rule" "nodeport" {
  type              = "ingress"
  from_port         = 30000
  to_port           = 32767
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = data.aws_security_group.rke2.id
  description       = "NodePort range for services"
}

resource "aws_security_group_rule" "rke2_supervisor" {
  type              = "ingress"
  from_port         = 9345
  to_port           = 9345
  protocol          = "tcp"
  cidr_blocks       = ["172.31.0.0/16"]
  security_group_id = data.aws_security_group.rke2.id
  description       = "RKE2 supervisor (internal)"
}

resource "aws_security_group_rule" "internal" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  self              = true
  security_group_id = data.aws_security_group.rke2.id
  description       = "Internal cluster traffic"
}

resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = data.aws_security_group.rke2.id
  description       = "Allow all outbound"
}