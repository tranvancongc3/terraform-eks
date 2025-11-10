variable "aws_region" {
  type        = string
  description = "AWS region for prod environment."
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR for prod."
  default     = "10.1.0.0/16"
}