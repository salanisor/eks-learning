variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN from the EKS cluster"
  type        = string
}

variable "oidc_provider_url" {
  description = "OIDC provider URL from the EKS cluster"
  type        = string
}

variable "role_name" {
  description = "Name for the IAM role"
  type        = string
}

variable "service_account_name" {
  description = "Kubernetes service account name to trust"
  type        = string
}

variable "service_account_namespace" {
  description = "Kubernetes namespace for the service account"
  type        = string
}

variable "policy_arns" {
  description = "List of IAM policy ARNs to attach to the role"
  type        = list(string)
  default     = []
}

variable "inline_policy" {
  description = "Optional inline policy JSON to attach"
  type        = string
  default     = ""
}