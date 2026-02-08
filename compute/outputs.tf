output "ecr_repo_uri" {
    value = aws_ecr_repository.image_repository.repository_url
}