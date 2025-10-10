# Variáveis de identificação padrão
variable "app_name" {
  description = "Nome base da aplicação para prefixo (ex: flowhub)."
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

variable "cognito_user_pool_arn" {
  description = "O ARN do Cognito User Pool para o autorizador da API Gateway."
  type        = string
}

variable "dynamodb_table_arn" {
  description = "O ARN da tabela DynamoDB à qual a Lambda precisa de acesso."
  type        = string
}

# Variáveis específicas da Lambda
variable "lambda_source_dir" {
  description = "Caminho para o diretório de código-fonte da lambda que será zipado."
  type        = string
}

variable "lambda_handler_path" {
  description = "O caminho completo do handler da lambda dentro do pacote zip (ex: invoke_step_Function.invoke_step_Function.lambda_handler)."
  type        = string
}

# Variáveis de configuração
variable "allowed_cors_origin" {
  description = "A origem permitida para o CORS. Use '*' para permitir todas."
  type        = string
  default     = "*"
}
variable "lambda_name" {
  description = "Nome explícito da função Lambda."
  type        = string
}

variable "lambda_iam_role_name" {
  description = "Nome explícito da IAM Role da Lambda."
  type        = string
}
variable "dynamodb_table_name_param" {
  description = "O nome da tabela DynamoDB para o status da tarefa."
  type        = string
}
variable "api_gateway_authorizer_id" {
  description = "O ID do autorizador compartilhado da API Gateway."
  type        = string
}
variable "stepfunction_arn" {
  description = "O ARN da Step Function a ser invocada."
  type        = string
}