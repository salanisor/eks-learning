variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN from EKS cluster"
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC provider URL from EKS cluster"
  type        = string
}

variable "chart_version" {
  description = "AWS Load Balancer Controller Helm chart version"
  type        = string
  default     = "1.7.2"
}