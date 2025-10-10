resource "aws_api_gateway_rest_api" "api" {
  name        = var.api_name
  description = "API Gateway para o ambiente ${var.environment}"
  tags        = var.tags
}