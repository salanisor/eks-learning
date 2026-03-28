output "namespace" {
  description = "Kubernetes namespace for this team"
  value       = kubernetes_namespace_v1.this.metadata[0].name
}

output "eso_role_arn" {
  description = "ESO IAM role ARN scoped to this team"
  value       = aws_iam_role.eso.arn
}

output "app_role_arn" {
  description = "App workload IAM role ARN"
  value       = aws_iam_role.app.arn
}

output "secret_store_name" {
  description = "Kubernetes SecretStore name for this team"
  value       = "${var.team_name}-secret-store"
}
