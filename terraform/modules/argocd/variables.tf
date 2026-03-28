variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "chart_version" {
  description = "ArgoCD Helm chart version"
  type        = string
  default     = "7.7.3"
}

variable "github_repo_url" {
  description = "GitHub repository URL for GitOps"
  type        = string
}

variable "argocd_namespace" {
  description = "Namespace for ArgoCD"
  type        = string
  default     = "argocd"
}
