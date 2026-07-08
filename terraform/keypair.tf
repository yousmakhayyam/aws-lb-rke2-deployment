# ✅ Data source (existing key pair)
data "aws_key_pair" "rke2" {
  key_name = "${var.cluster_name}-key"
}