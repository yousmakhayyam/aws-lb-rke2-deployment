variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "Name used to tag everything for this RKE2 cluster"
  type        = string
  default     = "yousma-rke2-cluster"
}

variable "instance_type" {
  description = "EC2 instance type for master and worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "my_ip_cidr" {
  description = "Your current public IP in CIDR form, e.g. 1.2.3.4/32 - so SSH/API is only open to you, not the whole internet. Find yours at https://checkip.amazonaws.com"
  type        = string
}
