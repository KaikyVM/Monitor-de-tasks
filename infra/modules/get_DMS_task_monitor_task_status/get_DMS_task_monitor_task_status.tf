
  locals {
    log_group_name = "/aws/lambda/${var.lambda_name}"
    lambda_zip_output_path = "${path.module}/get_DMS_task_monitor_task_status.zip"
  }

# DYNAMODB
resource "aws_dynamodb_table" "DMS_task_monitor_task_status" {
  # Usa o nome explícito
  name = var.dynamodb_table_name

  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "task_identifier"

  attribute {
    name = "task_identifier"
    type = "S"
  }

  tags = var.tags
}

# IAM E LAMBDA

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = var.lambda_source_dir_path
  output_path = local.lambda_zip_output_path
}

# Role e Policies
data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name               = var.lambda_iam_role_name
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
  tags               = var.tags 
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "lambda_service_permissions" {
  name = format("%s-get-status-permissions%s", var.app_name, var.environment == "" ? "" : "-${var.environment}")
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "dms:DescribeReplicationTasks",
          "dms:DescribeConnections",
          "dms:DescribeReplicationInstances",
          "dms:DescribeEndpoints"
        ],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:UpdateItem" ,
          "dynamodb:BatchGetItem"
        ],
        Resource = aws_dynamodb_table.DMS_task_monitor_task_status.arn
      },
      {
        Effect   = "Allow",
        Action   = ["states:DescribeExecution"],
        Resource = var.step_function_execution_arn_pattern
      }
    ]
  })
}


# Lambda
resource "aws_lambda_function" "get_DMS_task_monitor_task_status" {
  function_name = var.lambda_name
  #function_name = format("%s-get-task-status%s", var.app_name, var.environment == "" ? "" : "-${var.environment}")
  role             = aws_iam_role.lambda_role.arn
  handler          = var.lambda_handler_path
  runtime          = "python3.12"
  timeout          = 180
  memory_size      = 128
  filename         = local.lambda_zip_output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      REGION = var.aws_region
      DYNAMODB_TABLE_NAME = var.dynamodb_table_name
    }
  }

  depends_on = [
    aws_iam_role_policy.lambda_service_permissions,
    aws_cloudwatch_log_group.lambda_log_group
  ]
}

resource "aws_api_gateway_method" "post" {
  rest_api_id   = var.api_gateway_id
  resource_id   = aws_api_gateway_resource.get_task_status_resource.id
  http_method   = "POST"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = var.api_gateway_authorizer_id
}

resource "aws_api_gateway_resource" "get_task_status_resource" {
  rest_api_id = var.api_gateway_id
  parent_id   = var.api_gateway_parent_resource_id
  path_part   = "get_DMS_task_monitor_task_status"
}

resource "aws_api_gateway_integration" "post_integration" {
  rest_api_id             = var.api_gateway_id
  resource_id             = aws_api_gateway_resource.get_task_status_resource.id
  http_method             = aws_api_gateway_method.post.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.get_DMS_task_monitor_task_status.invoke_arn
}

resource "aws_lambda_permission" "allow_apigw" {
  statement_id_prefix = "AllowAPIGWInvoke"
  action              = "lambda:InvokeFunction"
  function_name       = aws_lambda_function.get_DMS_task_monitor_task_status.function_name
  principal           = "apigateway.amazonaws.com"

  # ARN genérico para qualquer endpoint DENTRO desta API
  source_arn = "${var.api_gateway_execution_arn}/*/*"
}

# --- Configuração de CORS (OPTIONS) ---
resource "aws_api_gateway_method" "options" {
  rest_api_id   = var.api_gateway_id
  resource_id   = aws_api_gateway_resource.get_task_status_resource.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id = var.api_gateway_id
  resource_id = aws_api_gateway_resource.get_task_status_resource.id
  http_method = aws_api_gateway_method.options.http_method
  type        = "MOCK"
  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }
}

resource "aws_api_gateway_method_response" "options_method_response" {
  rest_api_id = var.api_gateway_id
  resource_id = aws_api_gateway_resource.get_task_status_resource.id
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
  resource_id = aws_api_gateway_resource.get_task_status_resource.id
  http_method = aws_api_gateway_method.options.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'",
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'",
    "method.response.header.Access-Control-Allow-Origin"  ="'*'"
  }
  depends_on = [aws_api_gateway_integration.options_integration]
}
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = local.log_group_name
  retention_in_days = 14 
  tags              = var.tags
}