locals {
  subject_patterns = coalesce(var.subject_claim_patterns, [
    "repo:${var.github_org}/*:ref:refs/heads/*"
  ])

  ecr_repo_arns = length(var.ecr_repository_arns) > 0 ? var.ecr_repository_arns : ["*"]
}

resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = var.thumbprint_list
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "github_actions" {
  name               = "${var.name_prefix}-gh-actions-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRoleWithWebIdentity"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = local.subject_patterns
          }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "ecr_push" {
  name        = "${var.name_prefix}-gh-actions-ecr-push"
  description = "Allow GitHub Actions to push/pull images to ECR"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AuthToken"
        Effect = "Allow"
        Action = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid    = "RepositoryPushPull"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:BatchGetImage",
          "ecr:GetDownloadUrlForLayer",
          "ecr:DescribeRepositories",
          "ecr:ListImages"
        ]
        Resource = local.ecr_repo_arns
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecr_push" {
  role       = aws_iam_role.github_actions.name
  policy_arn = aws_iam_policy.ecr_push.arn
}

resource "aws_iam_role_policy_attachment" "extra" {
  for_each   = toset(var.additional_role_policy_arns)
  role       = aws_iam_role.github_actions.name
  policy_arn = each.value
}