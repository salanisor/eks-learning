output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_ca_certificate" {
  description = "Cluster CA certificate for kubeconfig"
  value       = aws_eks_cluster.main.certificate_authority[0].data
  sensitive   = true
}

output "node_role_arn" {
  description = "Node IAM role ARN"
  value       = aws_iam_role.nodes.arn
}

output "cluster_security_group_id" {
  description = "Control plane security group ID"
  value       = aws_security_group.cluster.id
}