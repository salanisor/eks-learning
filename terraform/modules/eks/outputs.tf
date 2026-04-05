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

output "oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA"
  value       = aws_iam_openid_connect_provider.cluster.arn
}

output "oidc_provider_url" {
  description = "OIDC provider URL for IRSA"
  value       = aws_eks_cluster.main.identity[0].oidc[0].issuer
}
output "node_group_id" {
  description = "Node group ID"
  value       = aws_eks_node_group.main.id
}
output "cluster_primary_security_group_id" {
  description = "EKS cluster primary security group ID used by nodes"
  value       = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
}
