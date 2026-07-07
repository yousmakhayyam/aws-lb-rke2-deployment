resource "random_password" "rke2_token" {
  length  = 32
  special = false
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}

# Elastic IP allocated BEFORE the instance, so we know the master's public
# IP ahead of time and can bake it into both the master's TLS cert and the
# worker's join config - avoids a chicken-and-egg dependency.
resource "aws_eip" "master" {
  domain = "vpc"
  tags   = { Name = "${var.cluster_name}-master-eip" }
}

resource "aws_instance" "master" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnet.chosen.id
  vpc_security_group_ids = [data.aws_security_group.rke2.id]
  iam_instance_profile   = data.aws_iam_instance_profile.node_profile.name
  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  user_data = templatefile("${path.module}/templates/master-userdata.sh.tpl", {
    rke2_token = random_password.rke2_token.result
    master_ip  = aws_eip.master.public_ip
  })

  tags = {
    Name                                        = "${var.cluster_name}-master"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }
}

resource "aws_eip_association" "master" {
  instance_id   = aws_instance.master.id
  allocation_id = aws_eip.master.id
}

resource "aws_instance" "worker" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = data.aws_subnet.chosen.id
  vpc_security_group_ids = [data.aws_security_group.rke2.id]
  key_name               = data.aws_key_pair.rke2.key_name
  iam_instance_profile   = data.aws_iam_instance_profile.node_profile.name

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  user_data = templatefile("${path.module}/templates/worker-userdata.sh.tpl", {
    rke2_token = random_password.rke2_token.result
    master_ip  = aws_eip.master.public_ip
  })

  tags = {
    Name                                        = "${var.cluster_name}-worker"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
  }

  depends_on = [aws_instance.master]
}