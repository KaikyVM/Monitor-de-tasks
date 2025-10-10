variable "api_name" {
  description = "O nome da API Gateway."
  type        = string
}
variable "environment" {
  description = "O nome do ambiente."
  type        = string
}
variable "tags" {
  description = "Tags a serem aplicadas."
  type        = map(string)
  default     = {}
}