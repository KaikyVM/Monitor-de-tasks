# IAM E LAMBDA
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.lambda_source_dir
  output_path = local.lambda_zip_output_path
}

# Role e Log Group
resource "aws_iam_role" "lambda_role" {
  #name = format("%s-test-dms-lambda-role%s", var.app_name, var.environment == "" ? "" : "-${var.environment}")
  path = "/service-role/"
  name = var.lambda_iam_role_name
  tags = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = local.log_group_name
  retention_in_days = 14
  tags              = var.tags
}

# Lambda
resource "aws_lambda_function" "teste_conectividade_dms" {
  #function_name = format("%s-test-dms%s", var.app_name, var.environment == "" ? "" : "-${var.environment}")
  function_name    = var.lambda_name
  role             = aws_iam_role.lambda_role.arn
  handler          = var.lambda_handler_path
  runtime          = "python3.12"
  timeout          = 180
  memory_size      = 128
  filename         = local.lambda_zip_output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  tags             = var.tags

  logging_config {
    log_group  = local.log_group_name
    log_format = "Text"
  }

  depends_on = [aws_cloudwatch_log_group.lambda_log_group]
}

# API GATEWAY

resource "aws_api_gateway_resource" "test_connection_endpoint" {
  rest_api_id = var.api_gateway_id
  parent_id   = var.api_gateway_parent_resource_id
  path_part   = "test-connection"
}

resource "aws_api_gateway_method" "post" {
  rest_api_id   = var.api_gateway_id
  resource_id   = aws_api_gateway_resource.test_connection_endpoint.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = var.api_gateway_authorizer_id 
}

resource "aws_api_gateway_integration" "post_integration" {
  rest_api_id             = var.api_gateway_id
  resource_id             = aws_api_gateway_resource.test_connection_endpoint.id
  http_method             = aws_api_gateway_method.post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.teste_conectividade_dms.invoke_arn
}

resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowAPIGatewayInvokeTestDMS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.teste_conectividade_dms.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${var.api_gateway_execution_arn}/*/*"
}

# CORS (OPTIONS)
resource "aws_api_gateway_method" "options" {
  rest_api_id   = var.api_gateway_id
  resource_id   = aws_api_gateway_resource.test_connection_endpoint.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id = var.api_gateway_id
  resource_id = aws_api_gateway_resource.test_connection_endpoint.id
  http_method = aws_api_gateway_method.options.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_method_response" {
  rest_api_id = var.api_gateway_id
  resource_id = aws_api_gateway_resource.test_connection_endpoint.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true,
    "method.response.header.Access-Control-Allow-Methods" = true,
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

resource "aws_api_gateway_integration_response" "options_integration_response" {
  rest_api_id = var.api_gateway_id
  resource_id = aws_api_gateway_resource.test_connection_endpoint.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'",
    "method.response.header.Access-Control-Allow-Origin"  = "'${var.allowed_cors_origin}'"
  }
  depends_on = [aws_api_gateway_integration.options_integration]
}
# política para permitir ações no DMS
resource "aws_iam_policy" "dms_permissions" {
  name        = "${var.lambda_iam_role_name}-DMSPolicy"
  path        = "/"
  description = "Permite que a Lambda teste e descreva conexões do DMS."

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dms:TestConnection",
          "dms:DescribeConnections"
        ]
        Effect   = "Allow"
        Resource = "*"  #ALTERAR 
      },
    ]
  })
}

# Anexa a nova política de DMS à role da Lambda
resource "aws_iam_role_policy_attachment" "dms_access" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.dms_permissions.arn
}
