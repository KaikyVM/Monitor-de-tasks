# Variáveis de identificação para nomear recursos
variable "app_name" {
  description = "Nome base da aplicação ."
  type        = string
}

variable "environment" {
  description = "Ambiente de deploy ."
  type        = string
}

# Variáveis específicas do Cognito Client
variable "cognito_callback_urls" {
  description = "Lista de URLs de callback ."
  type        = list(string)
}

variable "cognito_logout_urls" {
  description = "Lista de URLs de logout."
  type        = list(string)
}

# Variável para o domínio do Cognito (deve ser globalmente único)
variable "cognito_domain_prefix" {
  description = "Prefixo para o domínio do User Pool. Será combinado com o ambiente."
  type        = string
}

# Variável para os grupos de usuários
variable "user_groups" {
  description = "grupos de usuários a serem criados, com nomes e descrições."
  type        = map(string)
  default     = {}
}

# Variáveis para as funções Lambda
variable "pre_signup_lambda_source_file" {
  description = "Caminho para o arquivo pré-signup."
  type        = string
}

variable "post_confirmation_lambda_source_file" {
  description = "Caminho para o arquivo pós-confirmação."
  type        = string
}

variable "aws_region" {
  description = "Região da AWS ."
  type        = string
}

variable "user_pool_name" {
  description = "Nome explícito para o Cognito User Pool."
  type        = string
}
variable "user_pool_client_name" {
  description = "Nome explícito para o Cognito App Client."
  type        = string
}

variable "lambda_iam_role_name" {
  description = "Nome explícito da IAM Role das Lambdas do Cognito."
  type        = string
}

variable "pre_signup_lambda_name" {
  description = "Nome explícito da Lambda de pré-signup."
  type        = string
}

variable "post_conf_lambda_name" {
  description = "Nome explícito da Lambda de pós-confirmação."
  type        = string
}