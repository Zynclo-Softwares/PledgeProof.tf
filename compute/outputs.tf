output "ecr_repo_uri" {
    value = aws_ecr_repository.image_repository.repository_url
}

output "private_subnets" {
  value = local.private_subnet_ids
}