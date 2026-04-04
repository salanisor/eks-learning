output "eso_role_arn" {
  description = "ESO base IAM role ARN"
  value       = aws_iam_role.eso.arn
}
