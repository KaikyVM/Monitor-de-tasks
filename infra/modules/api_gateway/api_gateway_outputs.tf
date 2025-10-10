output "id" {
  description = "O ID da API Gateway criada."
  value       = aws_api_gateway_rest_api.api.id
}
output "execution_arn" {
  description = "O ARN de execução da API Gateway."
  value       = aws_api_gateway_rest_api.api.execution_arn
}
output "root_resource_id" {
  description = "O ID do recurso raiz (/) da API."
  value       = aws_api_gateway_rest_api.api.root_resource_id
}