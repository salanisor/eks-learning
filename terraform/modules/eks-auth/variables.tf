variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "node_role_arn" {
  description = "Node IAM role ARN — must always be present"
  type        = string
}

variable "admin_iam_arns" {
  description = "List of IAM user or role ARNs to grant cluster admin"
  type        = list(string)
  default     = []
}

variable "readonly_iam_arns" {
  description = "List of IAM user or role ARNs to grant read-only access"
  type        = list(string)
  default     = []
}

variable "node_group_id" {
  description = "Node group ID to ensure nodes exist before updating aws-auth"
  type        = string
  default     = ""
}
