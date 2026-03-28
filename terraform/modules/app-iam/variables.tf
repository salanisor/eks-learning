variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace for the workload"
  type        = string
}

variable "service_account_name" {
  description = "Kubernetes service account name"
  type        = string
}

variable "role_name" {
  description = "IAM role name for the workload"
  type        = string
}

variable "policy_arns" {
  description = "List of IAM policy ARNs to attach"
  type        = list(string)
  default     = []
}

variable "inline_policy_json" {
  description = "Optional inline policy JSON"
  type        = string
  default     = ""
}