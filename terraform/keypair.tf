# ✅ Use existing key pair (must be imported in AWS)
data "aws_key_pair" "rke2" {
  key_name = "yousma-rke2-cluster-new"
}