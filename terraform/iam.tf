# EC2 Assume Role Policy Document
data "aws_iam_policy_document" "ec2_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# ✅ Data source (existing role)
data "aws_iam_role" "node_role" {
  name = "${var.cluster_name}-node-role"
}

# ✅ Data source (existing instance profile)
data "aws_iam_instance_profile" "node_profile" {
  name = "${var.cluster_name}-node-profile"
}