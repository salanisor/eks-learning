variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "sns_email" {
  description = "Email address for alarm notifications"
  type        = string
}

variable "cpu_threshold" {
  description = "CPU utilization threshold percentage for alarm"
  type        = number
  default     = 80
}

variable "memory_threshold" {
  description = "Memory utilization threshold percentage for alarm"
  type        = number
  default     = 80
}