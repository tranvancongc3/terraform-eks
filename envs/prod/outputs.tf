output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "public_subnet_ids" {
  value = module.vpc.public_subnets
}

output "private_subnet_ids" {
  value = module.vpc.private_subnets
}

output "eks_cluster_name" {
  value       = module.eks.cluster_name
  description = "EKS cluster name (prod)."
}

output "eks_cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "EKS API endpoint (prod)."
}

output "eks_cluster_oidc_issuer_url" {
  value       = module.eks.cluster_oidc_issuer_url
  description = "OIDC issuer URL for IRSA (prod)."
}

output "eks_oidc_provider_arn" {
  value       = module.eks.oidc_provider_arn
  description = "OIDC provider ARN created by the EKS module (prod)."
}

output "rds_writer_endpoint" {
  value       = module.aurora.cluster_writer_endpoint
  description = "Aurora PostgreSQL writer endpoint (prod)."
}

output "rds_reader_endpoints" {
  value       = [module.aurora.cluster_reader_endpoint]
  description = "Aurora PostgreSQL reader endpoint list (prod)."
}

output "rds_db_name" {
  value       = module.aurora.db_name
  description = "Aurora initial DB name (prod)."
}

output "rds_secret_arn" {
  value       = module.aurora.secret_arn
  description = "Secrets Manager ARN storing the Aurora master password (prod)."
}

output "rds_secret_name" {
  value       = module.aurora.secret_name
  description = "Secrets Manager name storing the Aurora master password (prod)."
}