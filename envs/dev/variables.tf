variable "aws_region" {
  type        = string
  description = "AWS region for dev environment."
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR for dev."
  default     = "10.0.0.0/16"
}