output "lambda_function_name" {
  description = "O nome da função Lambda para teste de conectividade."
  value       = aws_lambda_function.teste_conectividade_dms.function_name
}

output "api_gateway_endpoint_invoke_url" {
  description = "URL do endpoint para testar a conectividade DMS."
  value = "https://${var.api_gateway_id}.execute-api.${var.aws_region}.amazonaws.com/${var.environment}${aws_api_gateway_resource.test_connection_endpoint.path}"
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