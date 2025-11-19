variable "app_name" {
  description = "nome da aplicação ()."
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

variable "access_token" {
  description = "GitHub Personal Access Token para o Amplify."
  type        = string
  sensitive   = true // Para não exibir o token nos logs
}
