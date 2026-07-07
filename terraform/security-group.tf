resource "aws_security_group" "rke2" {
  name        = "${var.cluster_name}-sg"
  description = "RKE2 cluster - SSH, k8s API, node ports, LB health checks"
  vpc_id      = data.aws_vpc.default.id

  # SSH - only from your own IP
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  # Kubernetes API - only from your own IP (so kubectl works from your laptop)
  ingress {
    description = "K8s API"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr]
  }

  # RKE2 supervisor port (agent joins server through this)
  ingress {
    description = "RKE2 supervisor"
    from_port   = 9345
    to_port     = 9345
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.default.cidr_block]
  }

  # NodePort range - Traefik + AWS NLB health checks land here
  ingress {
    description = "NodePort range (Traefik / NLB)"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Internal cluster traffic (pod/service networking) - open between nodes in this SG
  ingress {
    description = "Internal cluster traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.cluster_name}-sg" }
}
