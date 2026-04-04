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

variable "enable_resource_quota" {
  description = "Enable resource quota for the team namespace"
  type        = bool
  default     = false
}

variable "resource_quota_cpu_requests" {
  description = "Total CPU requests limit for the namespace"
  type        = string
  default     = "4"
}

variable "resource_quota_cpu_limits" {
  description = "Total CPU limits for the namespace"
  type        = string
  default     = "8"
}

variable "resource_quota_memory_requests" {
  description = "Total memory requests limit for the namespace"
  type        = string
  default     = "4Gi"
}

variable "resource_quota_memory_limits" {
  description = "Total memory limits for the namespace"
  type        = string
  default     = "8Gi"
}

variable "resource_quota_pods" {
  description = "Maximum number of pods in the namespace"
  type        = string
  default     = "20"
}
