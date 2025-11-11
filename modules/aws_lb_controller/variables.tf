variable "name_prefix" {
  description = "Fixed resource name prefix (e.g., prj-stock-dev)"
  type        = string
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}

variable "oidc_provider_arn" {
  description = "OIDC provider ARN from the EKS module"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID passed to the AWS Load Balancer Controller chart"
  type        = string
}

variable "region" {
  description = "AWS region for the chart (auto-detected if not provided)"
  type        = string
  default     = null
}

variable "tags" {
  description = "Common tags applied to IAM resources"
  type        = map(string)
  default     = {}
}

variable "namespace" {
  description = "Namespace to install the AWS Load Balancer Controller"
  type        = string
  default     = "kube-system"
}

variable "service_account_name" {
  description = "ServiceAccount name for the AWS Load Balancer Controller"
  type        = string
  default     = "aws-load-balancer-controller"
}