output "github_oidc_provider_arn" {
  description = "ARN of the GitHub OIDC identity provider"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "github_actions_role_arn" {
  description = "ARN of the IAM role assumed by GitHub Actions"
  value       = aws_iam_role.github_actions.arn
}

output "github_actions_role_name" {
  description = "Name of the IAM role assumed by GitHub Actions"
  value       = aws_iam_role.github_actions.name
}

output "ecr_push_policy_arn" {
  description = "ARN of the managed policy for ECR push/pull"
  value       = aws_iam_policy.ecr_push.arn
}