output "cognito_domain" {
  description = "The cognito user pool domain where google oauth is redirected."
  value = aws_cognito_user_pool_domain.pledge_domain.domain
}