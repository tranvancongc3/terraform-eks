## Removed aws_region variable; provider reads region from AWS_PROFILE or env vars

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR for prod."
  default     = "10.1.0.0/16"
}

variable "cluster_version" {
  type        = string
  description = "EKS Kubernetes version for prod."
  default     = "1.34"
}