# infra/modules/update_status_lambda/variables_update_status.tf

variable "app_name" {
  description = "Nome base da aplicação para nomear recursos."
  type        = string
  default     = "DMS_task_monitor"
}

variable "environment" {
  description = "Ambiente de deploy (dev, hml, prd)."
  type        = string
}

variable "lambda_name" {
  description = "Nome da função Lambda."
  type        = string
}

variable "lambda_iam_role_name" {
  description = "Nome da Role IAM para a Lambda."
  type        = string
}

variable "lambda_source_dir" {
  description = "Caminho do diretório do código-fonte da Lambda para zipar."
  type        = string
}

variable "lambda_handler_path" {
  description = "Caminho do handler da Lambda (ex: handler.handler)."
  type        = string
  default     = "handler.handler"
}

variable "dynamodb_table_arn" {
  description = "ARN da tabela DynamoDB para conceder permissões."
  type        = string
}

variable "dynamodb_table_name" {
  description = "Nome da tabela DynamoDB para a variável de ambiente."
  type        = string
}

variable "tags" {
  description = "Tags a serem aplicadas nos recursos."
  type        = map(string)
  default     = {}
}