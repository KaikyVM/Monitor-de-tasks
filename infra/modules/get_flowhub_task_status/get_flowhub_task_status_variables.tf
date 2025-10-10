variable "app_name" {
  description = "Nome base da aplicação."
  type        = string
}

variable "environment" {
  description = "Ambiente."
  type        = string
}

variable "tags" {
  description = "Tags para aplicar nos recursos."
  type        = map(string)
}
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

variable "lambda_source_dir_path" {
  description = "Caminho para o diretório de origem da função Lambda."
  type        = string
}

variable "lambda_handler_path" {
  description = "O caminho do handler da função Lambda (ex: nome_arquivo.handler)."
  type        = string
}

variable "cors_allow_origin" {
  description = "A origem permitida para o CORS (ex: 'https://meu-site.com')."
  type        = string
  default     = "*"
}
variable "aws_region" {
  description = "Região da AWS."
  type        = string
}
variable "dynamodb_table_name" {
  description = "Nome da tabela DynamoDB para o status da tarefa."
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
variable "cognito_user_pool_arn" {
  description = "ARN do User Pool do Cognito para o autorizador."
  type        = string
}
variable "step_function_execution_arn_pattern" {
  description = "O padrão do ARN para as execuções da Step Function que esta Lambda pode descrever."
  type        = string
} 
variable "api_gateway_authorizer_id" {
  description = "O ID do autorizador compartilhado da API Gateway."
  type        = string
}
