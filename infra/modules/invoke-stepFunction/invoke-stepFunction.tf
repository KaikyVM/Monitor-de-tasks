# ROLE E LAMBDA
locals {
  lambda_zip_output_path = "${path.module}/invoke_step_function.zip"
  log_group_name = "/aws/lambda/${var.lambda_name}"
}
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = local.log_group_name
  retention_in_days = 14
  tags              = var.tags
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.lambda_source_dir
  output_path = local.lambda_zip_output_path
}

# Role e Policies
resource "aws_iam_role" "invoke_lambda_role" {
  #name = format("%s-invoke-sfn-role%s", var.app_name, var.environment == "" ? "" : "-${var.environment}")
  name = var.lambda_iam_role_name

  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.invoke_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "step_functions_access" {
  role       = aws_iam_role.invoke_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSStepFunctionsFullAccess"
}

resource "aws_iam_policy" "dynamodb_access_policy" {
  name        = format("%s-invoke-dynamodb-policy%s", var.app_name, var.environment == "" ? "" : "-${var.environment}")
  description = "Permite acesso de leitura/escrita à tabela DynamoDB."

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      Action   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:UpdateItem"],
      Effect   = "Allow",
      Resource = var.dynamodb_table_arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "dynamodb_access_attach" {
  role       = aws_iam_role.invoke_lambda_role.name
  policy_arn = aws_iam_policy.dynamodb_access_policy.arn
}

# Lambda
resource "aws_lambda_function" "invoke_step_function" {
  function_name    = var.lambda_name
  role             = aws_iam_role.invoke_lambda_role.arn
  handler          = var.lambda_handler_path
  runtime          = "python3.12"
  timeout          = 15
  memory_size      = 128
  filename         = local.lambda_zip_output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  depends_on = [
    aws_iam_role_policy_attachment.basic_execution,
    aws_iam_role_policy_attachment.step_functions_access,
    aws_iam_role_policy_attachment.dynamodb_access_attach,
    aws_cloudwatch_log_group.lambda_log_group 
  ]
  environment {
    variables = {
       DYNAMODB_TABLE_NAME = var.dynamodb_table_name_param
       STEP_FUNCTION_ARN   = var.stepfunction_arn
    }
  }
}

resource "aws_api_gateway_resource" "invoke_resource" {
  rest_api_id = var.api_gateway_id
  parent_id   = var.api_gateway_parent_resource_id
  path_part   = "invoke"
}

# POST
resource "aws_api_gateway_method" "post" {
  rest_api_id   = var.api_gateway_id
  resource_id   = aws_api_gateway_resource.invoke_resource.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = var.api_gateway_authorizer_id 
 }

resource "aws_api_gateway_integration" "post_integration" {
  rest_api_id             = var.api_gateway_id
  resource_id             = aws_api_gateway_resource.invoke_resource.id
  http_method             = aws_api_gateway_method.post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.invoke_step_function.invoke_arn
}

resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowAPIGWInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.invoke_step_function.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*/${aws_api_gateway_method.post.http_method}${aws_api_gateway_resource.invoke_resource.path}"
}

# CORS (OPTIONS)
resource "aws_api_gateway_method" "options" {
  rest_api_id   = var.api_gateway_id
  resource_id   = aws_api_gateway_resource.invoke_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id = var.api_gateway_id
  resource_id = aws_api_gateway_resource.invoke_resource.id
  http_method = aws_api_gateway_method.options.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_response" {
  rest_api_id = var.api_gateway_id
  resource_id = aws_api_gateway_resource.invoke_resource.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Headers" = true
  }
}

resource "aws_api_gateway_integration_response" "options_integration_response" {
  rest_api_id = var.api_gateway_id
  resource_id = aws_api_gateway_resource.invoke_resource.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'${var.allowed_cors_origin}'",
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'",
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
  }
  depends_on = [aws_api_gateway_integration.options_integration]
}