# create a private ecr repository
resource "aws_ecr_repository" "image_repository" {
    name = var.ecr_repo_name
    image_tag_mutability = "IMMUTABLE"
    tags = var.default_tags
}

resource "aws_ecr_lifecycle_policy" "repository_policy" {
  repository = aws_ecr_repository.image_repository.name
  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Expire untagged images > 1 (keep newest)"
        selection = {
          tagStatus   = "untagged"
          countType   = "imageCountMoreThan"
          countNumber = 1  # ✅ Minimum allowed
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Keep last 5 tagged images"
        selection = {
          tagStatus   = "tagged"
          countType   = "imageCountMoreThan"
          countNumber = 5
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
