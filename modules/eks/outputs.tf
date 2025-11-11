output "cluster_name" {
  value       = module.eks.cluster_name
  description = "EKS cluster name."
}

output "cluster_endpoint" {
  value       = module.eks.cluster_endpoint
  description = "EKS cluster API server endpoint."
}

output "cluster_version" {
  value       = module.eks.cluster_version
  description = "Kubernetes version of the EKS cluster."
}

output "cluster_oidc_issuer_url" {
  value       = module.eks.cluster_oidc_issuer_url
  description = "OIDC issuer URL for IRSA."
}

output "oidc_provider_arn" {
  value       = try(module.eks.oidc_provider_arn, null)
  description = "OIDC provider ARN created by the EKS module (if enabled)."
}

output "cluster_security_group_id" {
  value       = module.eks.cluster_security_group_id
  description = "Cluster security group ID created by the EKS module."
}

output "node_security_group_id" {
  value       = module.eks.node_security_group_id
  description = "Node security group ID for managed node groups."
}