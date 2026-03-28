output "argocd_namespace" {
  description = "ArgoCD namespace"
  value       = kubernetes_namespace_v1.argocd.metadata[0].name
}

output "argocd_role_arn" {
  description = "ArgoCD IAM role ARN"
  value       = aws_iam_role.argocd.arn
}
