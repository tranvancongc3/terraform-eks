variable "name_prefix" {
  type        = string
  description = "Prefix for naming RDS resources."
}

variable "environment" {
  type        = string
  description = "Deployment environment (e.g., dev)."
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where RDS will be deployed."
}

variable "subnet_ids" {
  type        = list(string)
  description = "Subnet IDs for the DB subnet group (use private subnets)."
}

variable "allowed_security_group_ids" {
  type        = list(string)
  description = "Security Group IDs allowed to access PostgreSQL (port 5432)."
}

variable "db_name" {
  type        = string
  description = "Initial database name."
  default     = "stock_dev"
}

variable "username" {
  type        = string
  description = "Master username for the database."
  default     = "stockdev"
}

variable "publicly_accessible" {
  type        = bool
  description = "Whether the database is publicly accessible."
  default     = false
}

variable "allocated_storage" {
  type        = number
  description = "The allocated storage in GB for the DB instance."
  default     = 30
}

variable "storage_type" {
  type        = string
  description = "Storage type for the DB instance (gp2, gp3, io1)."
  default     = "gp2"
}

variable "instance_class" {
  type        = string
  description = "Instance class for DB (e.g., db.t3.medium)."
  default     = "db.t3.medium"
}

variable "backup_retention_period" {
  type        = number
  description = "Number of days to retain automated backups."
  default     = 7
}

variable "deletion_protection" {
  type        = bool
  description = "Enable deletion protection on the DB instance."
  default     = false
}

variable "apply_immediately" {
  type        = bool
  description = "Whether to apply modifications immediately."
  default     = true
}

variable "skip_final_snapshot" {
  type        = bool
  description = "Skip final snapshot on deletion of the primary instance."
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Common tags to apply to resources."
  default     = {}
}

variable "parameter_group_family" {
  type        = string
  description = "RDS parameter group family for PostgreSQL."
  default     = "postgres17"
}

variable "parameter_overrides" {
  type        = map(string)
  description = "Map of parameter name to value for the parameter group."
  default     = {}
}