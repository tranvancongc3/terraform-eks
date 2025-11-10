variable "environment" {
  type        = string
  description = "Environment name, e.g., dev or prod."
}

variable "name_prefix" {
  type        = string
  description = "Project prefix."
  default     = "prj-stock"
}

variable "vpc_cidr" {
  type        = string
  description = "Base VPC CIDR, e.g., 10.0.0.0/16."
}

variable "azs" {
  type        = list(string)
  description = "List of AZ names to use."
}

variable "enable_nat_gateway" {
  type        = bool
  description = "Whether to enable NAT Gateway(s)."
  default     = false
}

variable "single_nat_gateway" {
  type        = bool
  description = "Use a single NAT Gateway."
  default     = true
}

variable "enable_dns_hostnames" {
  type        = bool
  description = "Enable DNS hostnames on VPC."
  default     = true
}

variable "common_tags" {
  type        = map(string)
  description = "Tags applied to all resources."
  default     = {}
}