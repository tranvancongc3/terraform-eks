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