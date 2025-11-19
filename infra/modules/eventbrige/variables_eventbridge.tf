# infra/modules/eventbrige/variables_eventbridge.tf

variable "environment" {
  description = "O ambiente de deploy (ex: dev, hml, prd)."
  type        = string
}

variable "state_machine_arn" {
  description = "O ARN da Step Function que será monitorada."
  type        = string
}

variable "target_lambda_arn" {
  description = "O ARN da Lambda function que será invocada pelo evento."
  type        = string
}

variable "target_lambda_function_name" {
  description = "O nome da Lambda function para dar a permissão de invocação."
  type        = string
}

variable "tags" {
  description = "Tags a serem aplicadas nos recursos."
  type        = map(string)
  default     = {}
}
variable "app_name" {
  description = "Nome geral da aplicação."
  type        = string
}