output "cluster_writer_endpoint" {
  description = "Writer endpoint of the Aurora cluster."
  value       = aws_rds_cluster.this.endpoint
}

output "cluster_reader_endpoint" {
  description = "Reader endpoint of the Aurora cluster."
  value       = aws_rds_cluster.this.reader_endpoint
}

output "security_group_id" {
  description = "Security group ID for the Aurora cluster."
  value       = aws_security_group.aurora.id
}

output "db_name" {
  description = "Initial database name."
  value       = aws_rds_cluster.this.database_name
}

output "secret_arn" {
  description = "Secrets Manager ARN storing the master password."
  value       = aws_secretsmanager_secret.db_master_password.arn
}

output "secret_name" {
  description = "Secrets Manager name storing the master password."
  value       = aws_secretsmanager_secret.db_master_password.name
}