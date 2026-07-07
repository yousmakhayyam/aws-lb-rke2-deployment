# ✅ Data source (existing IAM policy)
data "aws_iam_policy" "aws_lb_controller" {
  name = "AWSLoadBalancerControllerIAMPolicy-${var.cluster_name}"
}