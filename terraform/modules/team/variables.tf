variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "team_name" {
  description = "Team or line of business name — used for namespace and secret paths"
  type        = string
}

variable "environment" {
  description = "Environment name — dev, staging, prod"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "aws_account_id" {
  description = "AWS account ID"
  type        = string
}

variable "app_policy_statements" {
  description = "Additional IAM policy statements for the app workload"
  type        = any
  default     = []
}