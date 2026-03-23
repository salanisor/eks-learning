output "controller_role_arn" {
  description = "IAM role ARN used by the ALB controller"
  value       = module.irsa.role_arn
}