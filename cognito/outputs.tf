output "cognito_domain" {
  description = "The custom cognito domain for OAuth."
  value = var.cognito_custom_domain
}

output "user_pool_id" {
  description = "The Cognito user pool ID."
  value = aws_cognito_user_pool.user_pool.id
}

output "app_client_id" {
  description = "The cognito user pool client id for the app."
  value = aws_cognito_user_pool_client.app_client.id
}