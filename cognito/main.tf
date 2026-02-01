
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