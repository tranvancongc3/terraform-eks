variable "name_prefix" {
  description = "Project/environment name prefix for resource naming"
  type        = string
}

variable "github_org" {
  description = "GitHub organization owner for OIDC trust"
  type        = string
}

variable "subject_claim_patterns" {
  description = "Allowed subject claim patterns for OIDC (e.g., repo:org/repo:ref:refs/heads/*)"
  type        = list(string)
  default     = null
}

variable "thumbprint_list" {
  description = "Root CA thumbprints for GitHub OIDC provider"
  type        = list(string)
  default     = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

variable "ecr_repository_arns" {
  description = "ECR repository ARNs allowed for push/pull actions; empty means all"
  type        = list(string)
  default     = []
}

variable "additional_role_policy_arns" {
  description = "Additional managed policies to attach to the GitHub Actions role"
  type        = list(string)
  default     = []
}