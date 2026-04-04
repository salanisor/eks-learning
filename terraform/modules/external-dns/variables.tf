variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "chart_version" {
  description = "ExternalDNS Helm chart version"
  type        = string
  default     = "1.15.0"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone ID to manage"
  type        = string
  default     = "Z06238381OIYPB4ITJ8RK"
}

variable "domain_filter" {
  description = "Domain filter for ExternalDNS"
  type        = string
  default     = "freebsd.tv"
}
