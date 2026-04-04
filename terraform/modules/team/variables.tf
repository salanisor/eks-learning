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
variable "repo_url" {
  description = "GitHub repository URL for GitOps"
  type        = string
  default     = "https://github.com/salanisor/eks-learning"
}

variable "ingress_order" {
  description = "ALB ingress group order for this team"
  type        = number
  default     = 50
}

variable "domain_name" {
  description = "Domain name for ingress hostname"
  type        = string
  default     = "keights.net"
}
