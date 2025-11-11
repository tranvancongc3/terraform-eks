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
  description = "EKS cluster name (dev)."
}

output "eks_cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "EKS API endpoint (dev)."
}

output "eks_cluster_oidc_issuer_url" {
  value       = module.eks.cluster_oidc_issuer_url
  description = "OIDC issuer URL for IRSA (dev)."
}

output "eks_oidc_provider_arn" {
  value       = module.eks.oidc_provider_arn
  description = "OIDC provider ARN created by the EKS module (dev)."
}

output "rds_writer_endpoint" {
  value       = module.postgres_single.writer_endpoint
  description = "RDS writer endpoint (dev)."
}

output "rds_reader_endpoints" {
  value       = []
  description = "RDS reader endpoints, if any (dev)."
}

output "rds_db_name" {
  value       = module.postgres_single.db_name
  description = "RDS initial DB name (dev)."
}

output "rds_username" {
  value       = module.postgres_single.username
  description = "RDS master username (dev)."
}

output "rds_secret_arn" {
  value       = module.postgres_single.secret_arn
  description = "Secrets Manager ARN storing the RDS master password (dev)."
}

output "rds_secret_name" {
  value       = module.postgres_single.secret_name
  description = "Secrets Manager name storing the RDS master password (dev)."
}