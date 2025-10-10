variable "app_name" {
  description = "nome da aplicação (flowhub-view)."
  type        = string
}

variable "environment" {
  description = "O nome do ambiente (dev, hml, prd)."
  type        = string
}

variable "repository_url" {
  description = "A URL do repo no CodeCommit."
  type        = string
}

variable "branch_name" {
  description = "O nome da branch que o Amplify vai monitorar (ex: main, develop)."
  type        = string
}

variable "branch_stage" {
  description = "O estágio do deploy no Amplify ."
  type        = string
  default     = "DEVELOPMENT"
}

variable "tags" {
  description = "Tags para aplicar nos recursos do Amplify." #acho q nn tem nenhuma
  type        = map(string)
  default     = {}
}

variable "app_name_override" {
  description = "Nome explícito do App Amplify para sincronização."
  type        = string
}

variable "iam_role_name" {
  description = "Nome explícito da IAM Role para sincronização."
  type        = string
}
variable "frontend_env_vars" {
  description = "Um mapa de variáveis de ambiente para o build do frontend."
  type        = map(string)
  default     = {}
}

# NOVAS VARIÁVEIS PARA O DOMÍNIO
variable "hosted_zone_name" {
  description = "O nome da Zona de DNS (Hosted Zone) no Route 53."
  type        = string
}

variable "subdomain_prefix" {
  description = "O prefixo a ser usado para o subdomínio (ex: 'audisin')."
  type        = string
}