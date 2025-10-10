output "api_gateway_endpoint_invoke_url" {
  description = "The invocation URL for the new invoke endpoint."
  value       = "${var.api_gateway_execution_arn}/${aws_api_gateway_resource.invoke_resource.path_part}"
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