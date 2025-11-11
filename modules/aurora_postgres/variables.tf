variable "name_prefix" {
  type        = string
  description = "Prefix for naming Aurora resources."
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g., prod)."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where Aurora will be deployed."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for the DB subnet group (use private subnets)."
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "CIDR blocks allowed to access PostgreSQL (port 5432)."
  default     = []
}

variable "allowed_security_group_ids" {
  type        = list(string)
  description = "Security Group IDs allowed to access PostgreSQL (port 5432)."
  default     = []
}

variable "db_name" {
  type        = string
  description = "Initial database name."
  default     = "appdb"
}

variable "master_username" {
  type        = string
  description = "Master username for the cluster."
  default     = "app"
}

variable "instance_class" {
  type        = string
  description = "Instance class for Aurora instances (e.g., db.t3.medium)."
  default     = "db.t3.medium"
}

variable "backup_retention_period" {
  type        = number
  description = "Number of days to retain automated backups."
  default     = 7
}

variable "deletion_protection" {
  type        = bool
  description = "Enable deletion protection on the cluster."
  default     = true
}

variable "apply_immediately" {
  type        = bool
  description = "Whether to apply modifications immediately."
  default     = true
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Skip final snapshot on deletion of the cluster."
  default     = true
}

variable "replica_count" {
  type        = number
  description = "Number of read replicas to create."
  default     = 1
}

variable "tags" {
  type        = map(string)
  description = "Common tags to apply to resources."
  default     = {}
}