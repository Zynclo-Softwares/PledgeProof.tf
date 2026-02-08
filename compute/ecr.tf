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
        rulePriority    = 1
        description     = "Expire untagged images"
        selection = {
          tagStatus = "untagged"
          countType = "imageCountMoreThan"
          countNumber = 0  # Expire ALL untagged (keep 0)
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority    = 2
        description     = "Keep last 5 tagged images"
        selection = {
          tagStatus = "tagged"
          countType = "imageCountMoreThan"
          countNumber = 5  # Keep newest 5, expire rest
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}
