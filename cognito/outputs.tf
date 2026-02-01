output "cognito_domain" {
  description = "The cognito user pool domain where google oauth is redirected."
  value = aws_cognito_user_pool_domain.pledge_domain.domain
}

output "app_client_id" {
  description = "The cognito user pool client id for the app."
  value = aws_cognito_user_pool_client.app_client.id
}