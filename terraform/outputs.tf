output "master_public_ip" {
  description = "Master node's public (Elastic) IP"
  value       = aws_eip.master.public_ip
}

output "worker_public_ip" {
  description = "Worker node's public IP"
  value       = aws_instance.worker.public_ip
}

output "ssh_to_master" {
  description = "Run this to SSH into the master"
  value       = "ssh -i ${var.cluster_name}-key.pem ubuntu@${aws_eip.master.public_ip}"
}

output "get_kubeconfig_command" {
  description = "Run this from your laptop to pull kubeconfig, then fix the server IP"
  value       = "scp -i ${var.cluster_name}-key.pem ubuntu@${aws_eip.master.public_ip}:/etc/rancher/rke2/rke2.yaml ./kubeconfig && (Get-Content ./kubeconfig) -replace '127.0.0.1', '${aws_eip.master.public_ip}' | Set-Content ./kubeconfig"
}

output "node_iam_role_name" {
  description = "IAM role name attached to both nodes (needed nowhere else now, it's automatic)"
  value       = data.aws_iam_role.node_role.name
}
output "ssh_private_key" {
  value     = file("${path.module}/${var.cluster_name}-key.pem")
  sensitive = true
}