
data "aws_caller_identity" "current" {}

#  IAM E LAMBDA 

resource "aws_iam_role" "iam_for_lambda" {
  name = var.lambda_iam_role_name
  # name = format("%s-cognito-trigger-lambda%s", var.app_name, var.environment == "" ? "" : "-${var.environment}")

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Pre-Signup
data "archive_file" "pre_signup_zip" {
  type        = "zip"
  source_file = var.pre_signup_lambda_source_file
  output_path = "${path.module}/pre_signup.zip"
}

resource "aws_lambda_function" "pre_signup_validator" {
  function_name = var.pre_signup_lambda_name
  #function_name = format("%s-pre-signup%s", var.app_name, var.environment == "" ? "" : "-${var.environment}")
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "pre_signup.lambda_handler"
  runtime       = "python3.12"
  filename      = data.archive_file.pre_signup_zip.output_path
  source_code_hash = data.archive_file.pre_signup_zip.output_base64sha256

  depends_on = [aws_iam_role_policy_attachment.lambda_logs]
}

resource "aws_lambda_permission" "allow_cognito_pre_signup" {
  statement_id  = "AllowCognitoToInvokePreSignup"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.pre_signup_validator.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.user_pool.arn
}

# Post-Confirmation
data "archive_file" "post_confirmation_zip" {
  type        = "zip"
  source_file = var.post_confirmation_lambda_source_file
  output_path = "${path.module}/post_confirmation.zip"
}

resource "aws_iam_policy" "cognito_group_management_policy" {
  name = format("%s-cognito-group-management%s", var.app_name, var.environment == "" ? "" : "-${var.environment}")

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action   = "cognito-idp:AdminAddUserToGroup",
      Effect   = "Allow",
      Resource = "arn:aws:cognito-idp:${var.aws_region}:${data.aws_caller_identity.current.account_id}:userpool/*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cognito_group_management" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.cognito_group_management_policy.arn
}

resource "aws_lambda_function" "post_confirmation_assigner" {
  #function_name = format("%s-post-confirmation%s", var.app_name, var.environment == "" ? "" : "-${var.environment}")
  function_name = var.post_conf_lambda_name
  role             = aws_iam_role.iam_for_lambda.arn
  handler          = "post_confirmation.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.post_confirmation_zip.output_path
  source_code_hash = data.archive_file.post_confirmation_zip.output_base64sha256

  depends_on = [aws_iam_role_policy_attachment.cognito_group_management]
}

resource "aws_lambda_permission" "allow_cognito_post_confirmation" {
  statement_id  = "AllowCognitoToInvokePostConfirmation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_confirmation_assigner.function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn    = aws_cognito_user_pool.user_pool.arn
}

# COGNITO

resource "aws_cognito_user_pool" "user_pool" {
  name = var.user_pool_name

  username_attributes    = ["email"]
  auto_verified_attributes = ["email"]
  deletion_protection    = "INACTIVE"

  lambda_config {
    pre_sign_up     = aws_lambda_function.pre_signup_validator.arn
    post_confirmation = aws_lambda_function.post_confirmation_assigner.arn
  }

  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  password_policy {
    minimum_length    = 8
    require_uppercase = true
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
  }

  schema {
    name                = "email"
    attribute_data_type = "String"
    mutable             = true
    required            = true
    string_attribute_constraints {
      min_length = "0"
      max_length = "2048"
    }
  }

  schema {
    name                = "nickname"
    attribute_data_type = "String"
    mutable             = true
    required            = true
    string_attribute_constraints {
      min_length = "0"
      max_length = "2048"
    }
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
  }
}

# Grupos de usuários
resource "aws_cognito_user_group" "user_groups" {
  for_each = var.user_groups

  name         = each.key
  description  = each.value
  user_pool_id = aws_cognito_user_pool.user_pool.id
}

# client
# Cole este bloco corrigido em infra/modules/cognito/main.tf

resource "aws_cognito_user_pool_client" "user_pool_client" {
  name = var.user_pool_client_name

  user_pool_id = aws_cognito_user_pool.user_pool.id

  # Atributos de sincronização
  generate_secret         = false
  auth_session_validity   = 3
  supported_identity_providers = ["COGNITO"]
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_CUSTOM_AUTH",
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_USER_AUTH"
  ]

  # Atributos de configuração
  callback_urls = var.cognito_callback_urls
  logout_urls   = var.cognito_logout_urls
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                 = ["email", "openid", "phone"]
  prevent_user_existence_errors      = "ENABLED"
  enable_token_revocation              = true

  access_token_validity  = 60
  id_token_validity      = 60
  refresh_token_validity = 5
  
  token_validity_units {
    access_token  = "minutes"
    id_token      = "minutes"
    refresh_token = "days"
  }
}

# dominio do cognito
resource "aws_cognito_user_pool_domain" "user_pool_domain" {
  domain       = format("%s%s", var.cognito_domain_prefix, var.environment == "" ? "" : "-${var.environment}")
  user_pool_id = aws_cognito_user_pool.user_pool.id
}
