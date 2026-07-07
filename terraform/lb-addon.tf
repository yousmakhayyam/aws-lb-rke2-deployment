# Tag the default VPC's subnets so AWS Load Balancer Controller can
# auto-discover them (fixes the classic EXTERNAL-IP: <pending> issue)
resource "aws_ec2_tag" "elb_role" {
  for_each    = toset(data.aws_subnets.default.ids)
  resource_id = each.value
  key         = "kubernetes.io/role/elb"
  value       = "1"
}

resource "aws_ec2_tag" "cluster_owned" {
  for_each    = toset(data.aws_subnets.default.ids)
  resource_id = each.value
  key         = "kubernetes.io/cluster/${var.cluster_name}"
  value       = "shared"
}

# Official IAM policy for the controller
data "http" "lbc_iam_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "aws_lb_controller" {
  name        = "AWSLoadBalancerControllerIAMPolicy-${var.cluster_name}"
  description = "Permissions required by the AWS Load Balancer Controller"
  policy      = data.http.lbc_iam_policy.response_body
}

resource "aws_iam_role_policy_attachment" "attach_lbc_policy" {
  role       = aws_iam_role.node_role.name
  policy_arn = aws_iam_policy.aws_lb_controller.arn
}
