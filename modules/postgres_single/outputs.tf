output "writer_endpoint" {
  description = "Endpoint for writes (single instance address)."
  value       = aws_db_instance.primary.address
}

output "db_name" {
  description = "Database name."
  value       = var.db_name
}

output "username" {
  description = "Master username for the database."
  value       = var.username
}

output "security_group_id" {
  description = "Security group ID protecting the database."
  value       = aws_security_group.rds.id
}

output "secret_arn" {
  description = "Secrets Manager ARN for the master password."
  value       = aws_secretsmanager_secret.db_master_password.arn
}

output "secret_name" {
  description = "Secrets Manager name for the master password."
  value       = aws_secretsmanager_secret.db_master_password.name
}