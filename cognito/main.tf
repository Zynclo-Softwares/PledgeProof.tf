
resource "aws_cognito_user_pool" "user_pool" {
  name = var.pool_name

  # should be able to sign in or up with email & password
  username_attributes = ["email"] 

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

  lifecycle {
    ignore_changes = [ schema ]
  }

  # tags
  tags = var.default_tags
}

resource "aws_cognito_user_pool_domain" "pledge_domain" {
  domain       = var.domain_name
  user_pool_id = aws_cognito_user_pool.user_pool.id
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
    "https://${var.domain_name}.auth.${data.aws_region.current.name}.amazoncognito.com/oauth2/idpresponse" ,
    "https://www.google.com" # for testing purpose
  ]
  logout_urls = [
    "${var.app_scheme}://signout",
    "https://${var.domain_name}.auth.${data.aws_region.current.name}.amazoncognito.com/logout"
  ]

  supported_identity_providers = ["Google"]

  # allow user password auth and refresh token auth beside oauth
  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]

  prevent_user_existence_errors = "ENABLED"
}