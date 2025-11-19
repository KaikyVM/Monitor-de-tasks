# VARIÁVEIS GERAIS

variable "app_name" {
  description = "Nome geral da aplicação."
  type        = string
}

variable "environment" {
  description = "Nome do ambiente (ex: dev, hml, prd). Deixe vazio para não adicionar sufixo."
  type        = string
}

variable "aws_region" {
  description = "Região da AWS."
  type        = string
}

variable "tags" {
  description = "Tags padrão para aplicar em todos os recursos."
  type        = map(string)
}
variable "hosted_zone_name" {
  description = "O nome da Zona de DNS (Hosted Zone) no Route 53."
  type        = string
}

variable "subdomain_prefix" {
  description = "O prefixo a ser usado para o subdomínio (ex: 'DMS_task_monitor')."
  type        = string
}

variable "api_gateway_parent_resource_path" {
  description = "Caminho do recurso pai na API Gateway."
  type        = string
}

# VARIÁVEIS DE NOMES EXATOS 

# Amplify
variable "amplify_branch_name" {
  description = "Nome da branch monitorada."
  type        = string
}
variable "amplify_branch_stage" {
  description = "Estágio de deploy da branch."
  type        = string
}
variable "cognito_user_groups" {
  description = "Mapa de grupos de usuários."
  type        = map(string)
}
variable "cognito_callback_url" {
  description = "URL de callback para o Cognito."
  type        = string
}

variable "cognito_logout_url" {
  description = "URL de logout para o Cognito."
  type        = string
}
variable "stepfunction_arn" {
  description = "O ARN completo da State Machine da Step Function."
  type        = string
}