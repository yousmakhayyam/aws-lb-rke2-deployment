# ✅ Terraform generate key (for ssh_private_key output)
resource "tls_private_key" "rke2" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# ✅ Data source (existing key - mat banao naya)
data "aws_key_pair" "rke2" {
  key_name = "${var.cluster_name}-key"
}