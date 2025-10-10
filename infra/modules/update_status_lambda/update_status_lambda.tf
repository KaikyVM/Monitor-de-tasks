# infra/modules/update_status_lambda/update_status_lambda.tf

# CRIAÇÃO DO ZIP E LOGS
locals {
  lambda_zip_output_path = "${path.module}/update_status_lambda.zip"
  log_group_name         = "/aws/lambda/${var.lambda_name}"
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

# ROLE E POLICIES IAM
resource "aws_iam_role" "update_status_lambda_role" {
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

# Permissão básica para escrever logs no CloudWatch
resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.update_status_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Política customizada para permitir escrita na tabela DynamoDB
resource "aws_iam_policy" "dynamodb_write_policy" {
  name        = "${var.app_name}-update-status-dynamodb-policy-${var.environment}"
  description = "Permite que a Lambda de update de status escreva na tabela DynamoDB."

  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{
      # Ações necessárias para atualizar o status.
      Action   = ["dynamodb:UpdateItem", "dynamodb:PutItem", "dynamodb:GetItem"],
      Effect   = "Allow",
      Resource = var.dynamodb_table_arn
    }]
  })
}

resource "aws_iam_role_policy_attachment" "dynamodb_access_attach" {
  role       = aws_iam_role.update_status_lambda_role.name
  policy_arn = aws_iam_policy.dynamodb_write_policy.arn
}

# RECURSO DA LAMBDA FUNCTION
resource "aws_lambda_function" "update_status_lambda" {
  function_name    = var.lambda_name
  role             = aws_iam_role.update_status_lambda_role.arn
  handler          = var.lambda_handler_path
  runtime          = "python3.12"
  timeout          = 10 # Pode ser um timeout curto, a função é rápida
  memory_size      = 128
  filename         = local.lambda_zip_output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  depends_on = [
    aws_iam_role_policy_attachment.basic_execution,
    aws_iam_role_policy_attachment.dynamodb_access_attach,
    aws_cloudwatch_log_group.lambda_log_group
  ]

  environment {
    variables = {
      # Usando DYNAMO_TABLE_NAME para ser consistente com o código Python que você criou
      DYNAMO_TABLE_NAME = var.dynamodb_table_name
    }
  }
}
