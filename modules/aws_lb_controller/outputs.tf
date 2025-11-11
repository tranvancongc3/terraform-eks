output "irsa_role_arn" {
  description = "IRSA role ARN for the AWS Load Balancer Controller"
  value       = module.lb_controller_irsa.arn
}

output "service_account_name" {
  description = "Installed ServiceAccount name"
  value       = var.service_account_name
}