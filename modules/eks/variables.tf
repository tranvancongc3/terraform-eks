variable "environment" {
  type        = string
  description = "Environment name, e.g., dev or prod."
}

variable "name_prefix" {
  type        = string
  description = "Project prefix used for naming resources."
}

variable "cluster_name" {
  type        = string
  description = "Override for EKS cluster name. Leave empty to use default naming."
  default     = ""
}

variable "cluster_version" {
  type        = string
  description = "EKS Kubernetes version, e.g., 1.29."
  default     = "1.34"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where EKS will be deployed."
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for EKS control plane and node groups."
}

variable "addons" {
  type        = map(any)
  description = "Map of EKS addons configuration passed through to the EKS module."
  default     = {}
}

variable "node_groups" {
  type        = map(any)
  description = "Map of EKS managed node groups configuration."
  default     = {}
}

variable "access_entries" {
  type        = map(any)
  description = "EKS access entries to grant IAM principals cluster access."
  default     = {}
}

variable "public_access_cidrs" {
  type        = list(string)
  description = "Allowed CIDRs for public access to the EKS API endpoint."
  default     = ["14.243.87.5/32","117.3.39.192/32", "14.252.145.82/32"]
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all EKS resources."
  default     = {}
}

variable "addons_timeouts" {
  type = object({
    create = optional(string)
    update = optional(string)
    delete = optional(string)
  })
  description = "Create, update, and delete timeout configurations for EKS addons"
  default     = {}
}

# Security Group naming controls (pass-through to upstream EKS module)
variable "security_group_name" {
  type        = string
  description = "Name to use for the EKS cluster security group"
  default     = null
}

variable "security_group_use_name_prefix" {
  type        = bool
  description = "Use the security group name as a prefix (true) or exact name (false)"
  default     = true
}

variable "node_security_group_name" {
  type        = string
  description = "Name to use for the node shared security group"
  default     = null
}

variable "node_security_group_use_name_prefix" {
  type        = bool
  description = "Use the node security group name as a prefix (true) or exact name (false)"
  default     = true
}

