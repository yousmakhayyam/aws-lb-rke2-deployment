# ✅ Data source (existing security group)
data "aws_security_group" "rke2" {
  name = "${var.cluster_name}-sg"
}

# ✅ Data source for existing rules (instead of creating)
# No need to recreate rules — they already exist in AWS!