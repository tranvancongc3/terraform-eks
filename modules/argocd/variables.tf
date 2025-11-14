variable "namespace" {
  description = "Namespace to install Argo CD"
  type        = string
  default     = "argocd"
}

variable "release_name" {
  description = "Helm release name for Argo CD"
  type        = string
  default     = "argo-cd"
}

variable "repository" {
  description = "Argo CD Helm repository URL"
  type        = string
  default     = "https://argoproj.github.io/argo-helm"
}

variable "values" {
  description = "Additional chart configuration values for Argo CD"
  type        = map(any)
  default     = {}
}

variable "chart_version" {
  description = "Argo CD Helm chart version"
  type        = string
  default     = "9.1.1"
}