
resource "aws_cognito_user_pool" "user_pool" {
  name = var.pool_name

  # should be able to sign in or up with email & password
  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  # user attributes (name, email, mail)
  schema {
    name                = "name"
    attribute_data_type = "String"
    mutable             = true
    required            = false
    string_attribute_constraints {
      min_length = 0
      max_length = 50 # name usually not very long
    }
  }

  schema {
    name                = "picture"
    attribute_data_type = "String"
    mutable             = true
    required            = false
    string_attribute_constraints {
        min_length = 1
        max_length = 2048 # URL length limit
    }
  }

  # password policy
  password_policy {
    minimum_length    = 8
    require_uppercase = true
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    temporary_password_validity_days = 7
  }

  # how users verify their email.
  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
    email_message        = "Your Pledge code: {####}"
    email_subject        = "Pledge Proof - Verify Email"
  }

  # invoke Lambda with user profile after confirmation
  lambda_config {
    post_confirmation = var.post_confirmation_lambda_arn
  }

  lifecycle {
    ignore_changes = [ schema ]
  }

  # tags
  tags = var.default_tags
}

# Dummy A record for zynclo.com — required by Cognito to validate the parent domain
# allow_overwrite ensures multiple deployments (test/prod) don't conflict
resource "aws_route53_record" "parent_domain" {
  zone_id         = data.aws_route53_zone.zynclo.zone_id
  name            = "zynclo.com"
  type            = "A"
  ttl             = 300
  records         = ["192.0.2.1"] # RFC 5737 TEST-NET — safe placeholder
  allow_overwrite = true
}

resource "aws_cognito_user_pool_domain" "cognito_domain" {
  domain          = var.cognito_custom_domain
  user_pool_id    = aws_cognito_user_pool.user_pool.id
  certificate_arn = aws_acm_certificate_validation.cognito_cert_verified.certificate_arn
  depends_on      = [aws_route53_record.parent_domain]
}

resource "aws_route53_record" "cognito_custom_domain" {
  zone_id = data.aws_route53_zone.zynclo.zone_id
  name    = var.cognito_custom_domain
  type    = "A"
  alias {
    name                   = aws_cognito_user_pool_domain.cognito_domain.cloudfront_distribution
    zone_id                = "Z2FDTNDATAQYW2" # CloudFront's fixed hosted zone ID
    evaluate_target_health = false
  }
}

resource "aws_cognito_identity_provider" "google" {
  user_pool_id = aws_cognito_user_pool.user_pool.id
  provider_name = "Google"
  provider_type = "Google"
  
  provider_details = {
    client_id     = var.gcp_client_id
    client_secret = var.gcp_client_secret
    authorize_scopes = "email profile openid"
  }
  
  attribute_mapping = {
    email    = "email"
    name     = "name" 
    picture  = "picture"
  }

   lifecycle {
    ignore_changes = [attribute_mapping, provider_details]
  }
}

# a client for server and mobile app
resource "aws_cognito_user_pool_client" "app_client" {
  name         = "${var.pool_name}-app-client"
  user_pool_id = aws_cognito_user_pool.user_pool.id
  generate_secret = false

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows = ["code"]
  allowed_oauth_scopes = ["email", "openid", "profile"]
  callback_urls = [
    "${var.app_scheme}://callback", # mobile app custom scheme
    "https://${var.cognito_custom_domain}/oauth2/idpresponse",
    "https://www.google.com",  # Testing purpose in web browser
    "exp://localhost:8081",    # Expo Go
    "exp://localhost:8081/--/" # Expo Go wildcard
  ]
  logout_urls = [
    "${var.app_scheme}://signout",
    "https://${var.cognito_custom_domain}/logout",
    "https://www.google.com",           # Web test
    "exp://localhost:8081",             # Expo Go
    "exp://localhost:8081/--/"          # Expo Go wildcard
  ]

  supported_identity_providers = ["Google"]

  # allow user password auth and refresh token auth beside oauth
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  prevent_user_existence_errors = "ENABLED"

  depends_on = [aws_cognito_identity_provider.google]
}

# Allow Cognito to invoke the event proxy Lambda
resource "aws_lambda_permission" "cognito_post_confirmation" {
  statement_id  = "AllowCognitoInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.post_confirmation_lambda_arn
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.user_pool.arn
}