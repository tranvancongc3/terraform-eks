output "repository_arns" {
  description = "ARNs of created ECR repositories"
  value       = [for r in aws_ecr_repository.this : r.arn]
}

output "repository_names" {
  description = "Names of created ECR repositories"
  value       = [for r in aws_ecr_repository.this : r.name]
}