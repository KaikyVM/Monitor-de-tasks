output "dynamodb_table_name" {
  description = "nome da Flowhub Task Status DynamoDB table."
  value       = aws_dynamodb_table.flowhub_task_status.name
}

output "dynamodb_table_arn" {
  description = " ARN do Flowhub Task Status DynamoDB table."
  value       = aws_dynamodb_table.flowhub_task_status.arn
}

output "api_gateway_endpoint_invoke_url" {
  description = "The invocation URL for the new endpoint."
  value       = "${var.api_gateway_execution_arn}/${aws_api_gateway_resource.get_task_status_resource.path_part}"
}

output "api_gateway_id" {
  description = "O ID da API Gateway utilizada pelo módulo."
  value       = var.api_gateway_id
}

# Adicione este código ao final do outputs.tf de cada um dos 3 módulos

output "post_integration" {
  description = "A integração do método POST da API Gateway."
  value       = aws_api_gateway_integration.post_integration
}

output "options_integration" {
  description = "A integração do método OPTIONS da API Gateway."
  value       = aws_api_gateway_integration.options_integration
}