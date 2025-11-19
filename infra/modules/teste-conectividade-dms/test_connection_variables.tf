# Variáveis de identificação padrão
variable "app_name" {
  description = "Nome base da aplicação para prefixo (ex: DMS_task_monitor)."
  type        = string
}

variable "environment" {
  description = "Ambiente de deploy (ex: dev, hml, prd)."
  type        = string
}

variable "tags" {
  description = "Tags a serem aplicadas aos recursos."
  type        = map(string)
  default     = {}
}

# Variáveis de recursos externos

variable "api_gateway_id" {
  description = "O ID da API Gateway a ser usada."
  type        = string
}
variable "api_gateway_execution_arn" {
  description = "O ARN de execução da API Gateway."
  type        = string
}
variable "api_gateway_parent_resource_id" {
  description = "O ID do recurso pai da API Gateway (geralmente o recurso '/dms')."
  type        = string
}
# Variáveis específicas da Lambda
variable "lambda_source_dir" {
  description = "Caminho para o diretório de código-fonte da lambda que será zipado."
  type        = string
}

variable "lambda_handler_path" {
  description = "O caminho completo do handler da lambda dentro do pacote zip (ex: lambda_teste_conectividade_dms.lambda_handler)."
  type        = string
}

# Variáveis de configuração
variable "allowed_cors_origin" {
  description = "A origem permitida para o CORS. Use '*' para permitir todas."
  type        = string
  default     = "*"
}
variable "aws_region" {
  description = "Região da AWS onde os recursos serão criados."
  type        = string
}

variable "lambda_name" {
  description = "Nome explícito da função Lambda."
  type        = string
}

variable "lambda_iam_role_name" {
  description = "Nome explícito da IAM Role da Lambda."
  type        = string
}

locals {
  lambda_zip_output_path = "${path.module}/lambda.zip"

  log_group_name = "/aws/lambda/${var.lambda_name}"
  #log_group_name = format("/aws/lambda/%s-test-dms%s", var.app_name, var.environment == "" ? "" : "-${var.environment}")
}
variable "cognito_user_pool_arn" {
  description = "ARN do User Pool do Cognito para o autorizador."
  type        = string
}
variable "api_gateway_authorizer_id" {
  description = "O ID do autorizador compartilhado da API Gateway."
  type        = string
}