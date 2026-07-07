# Terraform GENERATES the key pair this time, so it always exists
# alongside your code/state. Yousma - after apply, immediately email
# yourself "rke2-key.pem" or upload to OneDrive/Google Drive. Do not
# let it live only on the laptop again.

resource "tls_private_key" "rke2" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "rke2" {
  key_name   = "${var.cluster_name}-key"
  public_key = tls_private_key.rke2.public_key_openssh
}

resource "local_file" "private_key_pem" {
  content         = tls_private_key.rke2.private_key_pem
  filename        = "${path.module}/${var.cluster_name}-key.pem"
  file_permission = "0400"
}
