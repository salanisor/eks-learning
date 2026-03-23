variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "eks-learning"
}

variable "azs" {
  description = "Availability zones to deploy into"
  type        = list(string)
  default     = ["us-east-1b", "us-east-1c"]
}

# terraform/environments/dev/variables.tf
variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.35"
}