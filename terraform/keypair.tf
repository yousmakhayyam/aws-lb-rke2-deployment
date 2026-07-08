# ✅ Generate private key for Terraform state (pipeline ke liye)
resource "tls_private_key" "rke2" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# ✅ Reference existing key pair (DO NOT CREATE NEW)
data "aws_key_pair" "rke2" {
  key_name = "${var.cluster_name}-key"
}