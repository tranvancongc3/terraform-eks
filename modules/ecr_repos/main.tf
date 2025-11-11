resource "aws_ecr_repository" "this" {
  for_each = toset(var.repositories)
  name     = each.value

  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  tags = var.tags
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each  = toset(var.repositories)
  repository = aws_ecr_repository.this[each.value].name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep only latest ${var.retain_count} images"
        selection = {
          tagStatus   = "any"
          countType   = "imageCountMoreThan"
          countNumber = var.retain_count
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}