variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster endpoint"
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

variable "cluster_security_group_id" {
  description = "Cluster security group ID to tag for Karpenter discovery"
  type        = string
}
variable "cluster_primary_security_group_id" {
  description = "EKS cluster primary security group ID used by nodes"
  type        = string
}
