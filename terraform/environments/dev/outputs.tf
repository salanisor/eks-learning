output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnet_ids" {
  value = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.vpc.private_subnet_ids
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "test_app_namespace" {
  value = module.team_test_app.namespace
}

output "test_app_eso_role_arn" {
  value = module.team_test_app.eso_role_arn
}

output "test_app_app_role_arn" {
  value = module.team_test_app.app_role_arn
}

output "argocd_namespace" {
  value = module.argocd.argocd_namespace
}

output "argocd_role_arn" {
  value = module.argocd.argocd_role_arn
}

output "eso_role_arn" {
  value = module.external_secrets.eso_role_arn
}

output "sns_topic_arn" {
  value = module.cloudwatch_alarms.sns_topic_arn
}
output "karpenter_role_arn" {
  value = module.karpenter.karpenter_role_arn
}

output "interruption_queue_name" {
  value = module.karpenter.interruption_queue_name
}
